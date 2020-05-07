import ballerina/test;
import ballerina/io;

type Area record {
    int id;
    string name;
};

@test:Config {
    dependsOn: []
}
public function testSelectClause(){
    Angelina angl = new(new({
        url: "jdbc:mysql://localhost:3306/angelina",
        username: "root",
        password: "warurami",
        dbOptions: {useSSL: false}
    }));

    Builder query =  angl.createQuery("area");
    query.select([]);
    AngelinaQuery anglQuery = query.getQuery();

    io:println(anglQuery.query);

    
}