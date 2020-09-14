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

    io:println("TEST: Normal select All query");
    Builder query1 =  angl.createQuery("area");
    query1.select([]);
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT * FROM area");

    io:println("TEST: Select query with one column");
    Builder query2 =  angl.createQuery("area");
    query2.select(["column_a"]);
    AngelinaQuery anglQuery2 = query2.getQuery();
    test:assertEquals(anglQuery2.query, "SELECT column_a FROM area");

    io:println("TEST: Select query with one aliased column");
    Builder query3 =  angl.createQuery("area");
    query3.select([alias("column_a", "column_b")]);
    AngelinaQuery anglQuery3 = query3.getQuery();
    test:assertEquals(anglQuery3.query, "SELECT column_a AS column_b FROM area");

    io:println("TEST: Select query with more columns and more aliased columns");
    Builder query4 =  angl.createQuery("area");
    query4.select([alias("column_a", "column_b"), "column_c", alias("column_d", "column_e"), "column_f"]);
    AngelinaQuery anglQuery4 = query4.getQuery();
    test:assertEquals(anglQuery4.query, "SELECT column_a AS column_b , column_c , column_d AS column_e , column_f FROM area");

    io:println("TEST: Select query with value");
    Builder query5 =  angl.createQuery("area");
    query5.select([alias(5,"column_a")]);
    AngelinaQuery anglQuery5 = query5.getQuery();
    test:assertEquals(anglQuery5.parameters.length(),1);
    test:assertEquals(anglQuery5.parameters[0],5);
    test:assertEquals(anglQuery5.query, "SELECT ? AS column_a FROM area");

    io:println("TEST: Select query with sub query as table");
    Builder query6sub = angl.createQuery("area");
    query6sub.select(["column_a"]);
    Builder query6 =  angl.createQuery(alias(query6sub,"b"));
    query6.select([alias(5,"column_a")]);
    AngelinaQuery anglQuery6 = query6.getQuery();
    test:assertEquals(anglQuery6.query, "SELECT ? AS column_a FROM ( SELECT column_a FROM area ) AS b");

    io:println("TEST: Select query with sub query as column");
    Builder query7sub = angl.createQuery("area");
    query7sub.select(["column_a"]);
    Builder query7 =  angl.createQuery("area");
    query7.select([alias(query7sub,"column_b")]);
    AngelinaQuery anglQuery7 = query7.getQuery();
    test:assertEquals(anglQuery7.query, "SELECT ( SELECT column_a FROM area ) AS column_b FROM area");
}