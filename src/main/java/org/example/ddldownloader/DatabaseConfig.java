package org.example.ddldownloader;

/**
 * 数据库连接配置（支持从环境变量或默认值读取）
 */
public class DatabaseConfig {
    private String url;
    private String user;
    private String password;

    public DatabaseConfig() {
        // 优先从环境变量读取，其次使用默认值
        this.url = System.getenv().getOrDefault("DB_URL", "jdbc:oracle:thin:10.10.205.67:1522/ebs_UAT");
        this.user = System.getenv().getOrDefault("DB_USER", "apps");
        this.password = System.getenv().getOrDefault("DB_PASSWORD", "apps");
    }

    public DatabaseConfig(String url, String user, String password) {
        this.url = url;
        this.user = user;
        this.password = password;
    }

    public String getUrl() { return url; }
    public String getUser() { return user; }
    public String getPassword() { return password; }
}