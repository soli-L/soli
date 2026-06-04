package org.example.ddldownloader;

import java.io.*;
import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 负责从数据库下载对象 DDL 并保存到文件
 */
public class ObjectDownloader {
    private ConnectionManager connectionManager;
    // 支持的对象类型映射（用户输入 --> ALL_OBJECTS.OBJECT_TYPE 中的实际值）
    private static final Map<String, String> OBJECT_TYPE_MAP = new LinkedHashMap<>();

    static {
        OBJECT_TYPE_MAP.put("TABLE", "TABLE");
        OBJECT_TYPE_MAP.put("VIEW", "VIEW");
        OBJECT_TYPE_MAP.put("PACKAGE", "PACKAGE");
        OBJECT_TYPE_MAP.put("PACKAGE BODY", "PACKAGE BODY");
        OBJECT_TYPE_MAP.put("PROCEDURE", "PROCEDURE");
        OBJECT_TYPE_MAP.put("FUNCTION", "FUNCTION");
        OBJECT_TYPE_MAP.put("TRIGGER", "TRIGGER");
        OBJECT_TYPE_MAP.put("SEQUENCE", "SEQUENCE");
        OBJECT_TYPE_MAP.put("SYNONYM", "SYNONYM");
        OBJECT_TYPE_MAP.put("TYPE", "TYPE");
    }

    public ObjectDownloader(ConnectionManager connectionManager) {
        this.connectionManager = connectionManager;
    }

    /**
     * 执行下载操作
     *
     * @param schema      目标 Schema 名称
     * @param outputDir   输出根目录
     * @param objectTypes 要下载的对象类型列表（用户输入的名称，如 TABLE, VIEW）
     * @param since       下载该时间之后创建的对象
     */
    public void download(String schema, String outputDir, List<String> objectTypes, Timestamp since) {
        Connection conn = null;
        try {
            conn = connectionManager.getConnection();
            System.out.println("已连接到数据库，目标 Schema: " + schema.toUpperCase());
            if (since != null) {
                System.out.println("仅下载创建时间晚于 " + since + " 的对象");
            }
            System.out.println("对象类型: " + String.join(", ", objectTypes));

            // 将用户类型转换为 Oracle 内部类型
            List<String> oracleTypes = new ArrayList<>();
            for (String t : objectTypes) {
                String oracleType = OBJECT_TYPE_MAP.get(t.toUpperCase());
                if (oracleType != null) {
                    oracleTypes.add(oracleType);
                } else {
                    System.err.println("不支持的对象类型: " + t);
                }
            }
            if (oracleTypes.isEmpty()) {
                System.err.println("没有有效的对象类型，退出。");
                return;
            }

            List<ObjectInfo> objects = getObjects(conn, schema, oracleTypes, since);
            System.out.println("找到 " + objects.size() + " 个对象\n");

            for (int i = 0; i < objects.size(); i++) {
                ObjectInfo obj = objects.get(i);
                System.out.printf("[%d/%d] 处理 %s %s.%s%n",
                        i + 1, objects.size(), obj.type, schema.toUpperCase(), obj.name);
                try {
                    String ddl = getDDL(conn, schema, obj.name, obj.type);

                    if ("TABLE".equalsIgnoreCase(obj.type)) {
                        // 1. 给建表语句末尾加分号（Oracle DDL 默认不带分号）
                        ddl = ddl.trim() + ";\n";

                        // 2. 追加表注释
                        String tableComment = getTableComment(conn, schema, obj.name);
                        if (!tableComment.isEmpty()) {
                            ddl += tableComment;
                        }

                        // 3. 追加列注释
                        String colComments = getColumnComments(conn, schema, obj.name);
                        if (!colComments.isEmpty()) {
                            ddl += colComments;
                        }
                    }

                    saveDDL(outputDir, schema, obj.name, obj.type, ddl);
                } catch (Exception e) {
                    System.err.println("  ✗ 错误: " + e.getMessage());
                }
            }
        } catch (SQLException e) {
            System.err.println("数据库错误: " + e.getMessage());
        } finally {
            connectionManager.closeConnection(conn);
            System.out.println("\n数据库连接已关闭");
        }
    }

    /**
     * 查询目标 Schema 下指定类型的所有对象
     */
    private List<ObjectInfo> getObjects(Connection conn, String schema, List<String> oracleTypes, Timestamp since) throws SQLException {
        List<ObjectInfo> objects = new ArrayList<>();
        String typeList = oracleTypes.stream().map(t -> "'" + t + "'").collect(Collectors.joining(","));

        StringBuilder query = new StringBuilder(
                "SELECT object_name, object_type FROM all_objects " +
                        "WHERE owner = ? AND object_type IN (" + typeList + ") AND status = 'VALID'"
        );

        if (since != null) {
            query.append(" AND created > ?");
        }
        query.append(" ORDER BY object_type, object_name");

        try (PreparedStatement pstmt = conn.prepareStatement(query.toString())) {
            pstmt.setString(1, schema.toUpperCase());
            if (since != null) {
                pstmt.setTimestamp(2, since);
            }
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    objects.add(new ObjectInfo(rs.getString("object_name"), rs.getString("object_type")));
                }
            }
        }
        return objects;
    }

    /**
     * 调用 DBMS_METADATA.GET_DDL 获取单个对象的 DDL
     */
    private String getDDL(Connection conn, String schema, String objectName, String objectType) throws SQLException {
        String ddl;
        // 使用 CallableStatement 调用函数，返回 CLOB
        String sql = "{ ? = call DBMS_METADATA.GET_DDL(?, ?, ?) }";
        try (CallableStatement cstmt = conn.prepareCall(sql)) {
            cstmt.registerOutParameter(1, java.sql.Types.CLOB);
            cstmt.setString(2, objectType.toUpperCase());   // object_type
            cstmt.setString(3, objectName.toUpperCase());   // object_name
            cstmt.setString(4, schema.toUpperCase());       // schema
            cstmt.execute();
            Clob clob = cstmt.getClob(1);
            if (clob != null) {
                ddl = clob.getSubString(1, (int) clob.length());
            } else {
                ddl = "";
            }
        }
        return ddl;
    }

    /**
     * 将 DDL 内容写入文件，按类型分目录
     */
    private void saveDDL(String baseDir, String schema, String objectName, String objectType, String ddl) throws IOException {
        String safeName = objectName.replace("/", "_");
        String typeDir = objectType.toLowerCase().replace(" ", "_");
        String dirPath = baseDir + File.separator + schema.toLowerCase() + File.separator + typeDir;
        File dir = new File(dirPath);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        // 根据对象类型获取文件后缀，未映射的默认 .sql
        String suffix = TYPE_SUFFIX_MAP.getOrDefault(objectType.toUpperCase(), ".sql");
        File file = new File(dir, safeName + suffix);

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {
            writer.write(ddl);
        }
        System.out.println("  ✓ 已保存: " + file.getAbsolutePath());
    }

    // 内部类，封装对象名称和类型
    private static class ObjectInfo {
        String name;
        String type;

        ObjectInfo(String name, String type) {
            this.name = name;
            this.type = type;
        }
    }

    private static final Map<String, String> TYPE_SUFFIX_MAP = new HashMap<>();

    static {
        TYPE_SUFFIX_MAP.put("TABLE", ".sql");
        TYPE_SUFFIX_MAP.put("VIEW", ".sql");
        TYPE_SUFFIX_MAP.put("PACKAGE", ".spc");        // 包规范
        TYPE_SUFFIX_MAP.put("PACKAGE BODY", ".bdy");   // 包体
        // 其他类型默认使用 .sql，可以不添加或设为 ".sql"
    }

    /**
     * 获取表的 COMMENT ON TABLE 语句
     *
     * @return COMMENT ON TABLE schema.table IS '注释'; 若注释为空则返回空字符串
     */
    private String getTableComment(Connection conn, String schema, String tableName) throws SQLException {
        String sql = "SELECT comments FROM all_tab_comments WHERE owner = ? AND table_name = ? AND comments IS NOT NULL";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, schema.toUpperCase());
            pstmt.setString(2, tableName.toUpperCase());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    String comment = rs.getString("comments");
                    if (comment != null && !comment.isEmpty()) {
                        // 转义单引号，避免 SQL 注入/语法错误（注释中可能包含单引号）
                        comment = comment.replace("'", "''");
                        return String.format("COMMENT ON TABLE %s.%s IS '%s';\n", schema.toUpperCase(), tableName.toUpperCase(), comment);
                    }
                }
            }
        }
        return ""; // 无注释
    }

    private String getColumnComments(Connection conn, String schema, String tableName) throws SQLException {
        StringBuilder sb = new StringBuilder();
        String sql = "SELECT c.column_name, m.comments " +
                "FROM all_col_comments m " +
                "JOIN all_tab_columns c ON c.owner = m.owner AND c.table_name = m.table_name AND c.column_name = m.column_name " +
                "WHERE m.owner = ? AND m.table_name = ? AND m.comments IS NOT NULL " +
                "ORDER BY c.column_id";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, schema.toUpperCase());
            pstmt.setString(2, tableName.toUpperCase());
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String col = rs.getString("column_name");
                    String comment = rs.getString("comments");
                    if (comment != null && !comment.isEmpty()) {
                        comment = comment.replace("'", "''");
                        sb.append(String.format("COMMENT ON COLUMN %s.%s.%s IS '%s';\n",
                                schema.toUpperCase(), tableName.toUpperCase(), col.toUpperCase(), comment));
                    }
                }
            }
        }
        return sb.toString();
    }
}