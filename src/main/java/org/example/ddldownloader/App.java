package org.example.ddldownloader;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.*;

public class App {
    private static Properties configProps = new Properties();


    public static void main(String[] args) {
        // 改为：
        List<String> schemas = new ArrayList<>();
        Timestamp afterTime = null;
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        // 1. 加载 application.properties（如果存在）
        loadDefaultProperties();

        // 2. 用配置文件的值作为初始默认值
        //String schema = configProps.getProperty("schema");
        if (schemas.isEmpty()) {
            String schemasStr = configProps.getProperty("schema");
            if (schemasStr != null && !schemasStr.trim().isEmpty()) {
                schemas.addAll(Arrays.asList(schemasStr.trim().split("\\s*,\\s*")));
            }
        }
        String outputDir = configProps.getProperty("output.dir", "./output");
        String typesStr = configProps.getProperty("object.types", "TABLE,VIEW,PACKAGE,PACKAGE BODY");
        List<String> objectTypes = new ArrayList<>(Arrays.asList(typesStr.split("\\s*,\\s*")));

        String dbUrl = configProps.getProperty("db.url");
        String dbUser = configProps.getProperty("db.user");
        String dbPassword = configProps.getProperty("db.password");

        // 3. 命令行参数解析（可覆盖配置文件的值）
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-s":
                case "--schema":
                    // 收集所有后续非 `-` 开头的参数作为 schema 名称
                    while (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        schemas.add(args[++i]);
                    }
                    break;
                case "-o":
                case "--output":
                    outputDir = args[++i];
                    break;
                case "-t":
                case "--types":
                    objectTypes.clear();
                    while (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        objectTypes.add(args[++i]);
                    }
                    break;
                case "-url":
                    dbUrl = args[++i];
                    break;
                case "-user":
                    dbUser = args[++i];
                    break;
                case "-password":
                    dbPassword = args[++i];
                    break;
                case "--after":
                    String timeStr = args[++i];
                    try {
                        afterTime = new Timestamp(dateFormat.parse(timeStr).getTime());
                    } catch (Exception e) {
                        System.err.println("日期格式错误，请使用 yyyy-MM-dd HH:mm:ss，例如 \"2024-01-01 12:00:00\"");
                        System.exit(1);
                    }
                    break;
                default:
                    System.err.println("未知参数: " + args[i]);
                    printUsage();
                    System.exit(1);
            }
        }

        if (schemas.isEmpty()) {
            System.err.println("错误：必须指定至少一个 Schema (-s)");
            printUsage();
            System.exit(1);
        }

        // 4. 构建配置并执行
        DatabaseConfig config;
        if (dbUrl != null && dbUser != null && dbPassword != null) {
            config = new DatabaseConfig(dbUrl, dbUser, dbPassword);
        } else {
            config = new DatabaseConfig();  // 回退到环境变量
        }

        ConnectionManager cm = new ConnectionManager(config);
        ObjectDownloader downloader = new ObjectDownloader(cm);
        //downloader.download(schema, outputDir, objectTypes, afterTime);
        for (String schema : schemas) {
            System.out.println("\n========== 开始处理 Schema: " + schema.toUpperCase() + " ==========");
            downloader.download(schema, outputDir, objectTypes, afterTime);
        }
    }

    /**
     * 从 classpath 加载 application.properties
     */
    private static void loadDefaultProperties() {
        try (InputStream in = App.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                configProps.load(in);
                System.out.println("已加载 application.properties");
            } else {
                System.out.println("未找到 application.properties，将使用环境变量和命令行参数");
            }
        } catch (IOException e) {
            System.err.println("读取 application.properties 失败: " + e.getMessage());
        }
    }

    private static void printUsage() {
        System.out.println("用法: java -jar oracle-ddl-downloader.jar -s <schema> [选项]");
        System.out.println("  -s, --schema <名称>       目标 Schema 名称 (必选)");
        System.out.println("  -o, --output <目录>       输出目录 (默认: ./output)");
        System.out.println("  -t, --types <类型列表>    对象类型，多个用空格分隔");
        System.out.println("                            支持: TABLE, VIEW, PACKAGE, PACKAGE BODY, PROCEDURE, FUNCTION, TRIGGER, SEQUENCE, SYNONYM, TYPE");
        System.out.println("                            默认: TABLE VIEW PACKAGE \"PACKAGE BODY\"");
        System.out.println("  -url <JDBC URL>           Oracle 连接字符串");
        System.out.println("  -user <用户名>           数据库用户名");
        System.out.println("  -password <密码>         数据库密码");
        System.out.println("如果未提供连接信息，将从环境变量 DB_URL, DB_USER, DB_PASSWORD 读取，或使用默认值。");
    }
}