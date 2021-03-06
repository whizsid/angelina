// Main angelina wrapper

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

    # Create a angelina query
    # 
    # + tableName - Main table name or alias
    # + return - Angelina query Builder
    public function createQuery(UseAsTable tableName) returns Builder{
        Builder builder =  new(self.jdbcClient, tableName);
        return builder;
    }

};