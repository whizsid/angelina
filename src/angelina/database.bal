import ballerinax/java.jdbc;

public type FindOptions record {
    string[] relations=[];
    int skip=0;
    int limit?;
};

# This is the main wrapper of the angelina.
public type Angelina object {
    jdbc:Client jdbcClient;

    public function __init(jdbc:Client c) {
        self.jdbcClient = c;
    }

    public function find( typedesc<map<anydata>> td, int[] ids, FindOptions options ={}) returns map<anydata>[]{
        
        map<anydata>|error entity = td.constructFrom({});

        if entity is error {
            return [] ;
        } else {
           return [];
        }
    }

    public function findOne(typedesc<map<anydata>> td, int id) returns map<anydata>|error {
        map<anydata>|error entity = td.constructFrom({});

        if entity is error {
            return error("Entity Not Found") ;
        } else {
           return {};
        }
    }



};