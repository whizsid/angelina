import ballerina/test;
import ballerina/io;

type Area record {
    int id;
    string name;
};

Angelina angl = new(new({
    url: "jdbc:mysql://localhost:3306/angelina",
    username: "root",
    password: "warurami",
    dbOptions: {useSSL: false}
}));

@test:Config {
    dependsOn: []
}
public function testSelectClause(){
    io:println("TEST: Normal select All query");
    Builder query1 =  angl.createQuery(t("area"));
    query1.select([]);
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT * FROM area");

    io:println("TEST: Select query with one column");
    Builder query2 =  angl.createQuery(t("area"));
    query2.select([c("column_a")]);
    AngelinaQuery anglQuery2 = query2.getQuery();
    test:assertEquals(anglQuery2.query, "SELECT column_a FROM area");

    io:println("TEST: Select query with one aliased column");
    Builder query3 =  angl.createQuery(t("area"));
    query3.select([a(c("column_a"), "column_b")]);
    AngelinaQuery anglQuery3 = query3.getQuery();
    test:assertEquals(anglQuery3.query, "SELECT column_a AS column_b FROM area");

    io:println("TEST: Select query with more columns and more aliased columns");
    Builder query4 =  angl.createQuery(t("area"));
    query4.select([a(c("column_a"), "column_b"), c("column_c"), a(c("column_d"), "column_e"), c("column_f")]);
    AngelinaQuery anglQuery4 = query4.getQuery();
    test:assertEquals(anglQuery4.query, "SELECT column_a AS column_b , column_c , column_d AS column_e , column_f FROM area");

    io:println("TEST: Select query with value");
    Builder query5 =  angl.createQuery(t("area"));
    query5.select([a(v(5),"column_a")]);
    AngelinaQuery anglQuery5 = query5.getQuery();
    test:assertEquals(anglQuery5.parameters.length(),1);
    test:assertEquals(anglQuery5.parameters[0],5);
    test:assertEquals(anglQuery5.query, "SELECT ? AS column_a FROM area");

    io:println("TEST: Select query with sub query as column");
    Builder query7sub = angl.createQuery(t("area"));
    query7sub.select([c("column_a")]);
    Builder query7 =  angl.createQuery(t("area"));
    query7.select([a(query7sub,"column_b")]);
    AngelinaQuery anglQuery7 = query7.getQuery();
    test:assertEquals(anglQuery7.query, "SELECT ( SELECT column_a FROM area ) AS column_b FROM area");


}

@test:Config {
    dependsOn: []
}
public function testFromClause(){

    io:println("TEST: Select query with sub query as table");
    Builder query1sub = angl.createQuery(t("area"));
    query1sub.select([c("column_a")]);
    Builder query1 =  angl.createQuery(a(query1sub,"b"));
    query1.select([a(v(5),"column_a")]);
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT ? AS column_a FROM ( SELECT column_a FROM area ) AS b");


    io:println("TEST: Delete query");
    Builder query2 = angl.createQuery(t("area"));

    query2.delete();

    AngelinaQuery anglQuery2 = query2.getQuery();

    test:assertEquals(anglQuery2.query, "DELETE FROM area");
}