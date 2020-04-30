import ballerinax/java.jdbc;


public type Database object {
    jdbc:Client jdbcClient;

    public function __init(jdbc:Client c) {
        self.jdbcClient = c;
    }

};