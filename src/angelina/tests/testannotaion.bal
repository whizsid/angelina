import ballerina/io;
import ballerina/test;
import ballerinax/java.jdbc;

@Entity{ 
    primary:"id" ,
    tableName: "Actor",
    fields: {
        name: jdbc:TYPE_VARCHAR,
        id: jdbc:TYPE_INTEGER
    },
    relations: {
        films: <ManyToManyRelation> {
            entity: Film,
            foreignKey: "id",
            otherKey: "id",
            mapForeignKey: "film_id",
            mapOtherKey: "actor_id",
            mapTableName: "actor_hotel",
            name: "films"
        }
    }
}
type Actor record {
    string? name;
    int? id;
    Film[] films = [];
};

@Entity{ 
    primary:"id" ,
    tableName: "Film",
    fields: {
        name: jdbc:TYPE_VARCHAR,
        id: jdbc:TYPE_INTEGER
    },
    relations: {
        actors: <ManyToManyRelation> {
            entity: Actor,
            foreignKey: "id",
            otherKey: "id",
            mapForeignKey: "actor_id",
            mapOtherKey: "film_id",
            mapTableName: "actor_hotel",
            name: "actors"
        }
    }
}
type Film record {
    string? name;
    int? id;
    Actor[] actors = [];
};

// Test function.
@test:Config {
    dependsOn: []
}
function testFunction1() {


    Actor a1 = {
        name: "Irrfan Khan",
        id: 1
    };

    typedesc<Actor> td = typeof a1;
    io:println(Actor);

    string? tableName = td.@Entity?.tableName;

    // test:assertEquals(tableName, "Actor");
}
