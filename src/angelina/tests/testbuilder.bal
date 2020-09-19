import ballerina/io;
import ballerina/test;

type Area record {
    int id;
    string name;
};

Angelina angl = new (new ({
    url: "jdbc:mysql://localhost:3306/angelina",
    username: "root",
    password: "warurami",
    dbOptions: {useSSL: false}
}));

@test:Config {}
public function testSelectClause() {
    io:println("TEST: Normal select All query");
    Builder query1 = angl.createQuery(t("area"));
    query1.select([]);
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT * FROM area");

    io:println("TEST: Select query with one column");
    Builder query2 = angl.createQuery(t("area"));
    query2.select([c("column_a")]);
    AngelinaQuery anglQuery2 = query2.getQuery();
    test:assertEquals(anglQuery2.query, "SELECT column_a FROM area");

    io:println("TEST: Select query with one aliased column");
    Builder query3 = angl.createQuery(t("area"));
    query3.select([a(c("column_a"), "column_b")]);
    AngelinaQuery anglQuery3 = query3.getQuery();
    test:assertEquals(anglQuery3.query, "SELECT column_a AS column_b FROM area");

    io:println("TEST: Select query with more columns and more aliased columns");
    Builder query4 = angl.createQuery(t("area"));
    query4.select([a(c("column_a"), "column_b"), c("column_c"), a(c("column_d"), "column_e"), c("column_f")]);
    AngelinaQuery anglQuery4 = query4.getQuery();
    test:assertEquals(anglQuery4.query, "SELECT column_a AS column_b , column_c , column_d AS column_e , column_f FROM area");

    io:println("TEST: Select query with value");
    Builder query5 = angl.createQuery(t("area"));
    query5.select([a(v(5), "column_a")]);
    AngelinaQuery anglQuery5 = query5.getQuery();
    test:assertEquals(anglQuery5.parameters.length(), 1);
    test:assertEquals(anglQuery5.parameters[0], 5);
    test:assertEquals(anglQuery5.query, "SELECT ? AS column_a FROM area");

    io:println("TEST: Select query with sub query as column");
    Builder query7sub = angl.createQuery(t("area"));
    query7sub.select([c("column_a")]);
    Builder query7 = angl.createQuery(t("area"));
    query7.select([a(query7sub, "column_b")]);
    AngelinaQuery anglQuery7 = query7.getQuery();
    test:assertEquals(anglQuery7.query, "SELECT ( SELECT column_a FROM area ) AS column_b FROM area");


}

@test:Config {}
public function testFromClause() {

    io:println("TEST: Select query with sub query as table");
    Builder query1sub = angl.createQuery(t("area"));
    query1sub.select([c("column_a")]);
    Builder query1 = angl.createQuery(a(query1sub, "b"));
    query1.select([a(v(5), "column_a")]);
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT ? AS column_a FROM ( SELECT column_a FROM area ) AS b");


    io:println("TEST: Delete query");
    Builder query2 = angl.createQuery(t("area"));

    query2.delete();

    AngelinaQuery anglQuery2 = query2.getQuery();

    test:assertEquals(anglQuery2.query, "DELETE FROM area");
}

@test:Config {}
public function testSetClause() {
    io:println("TEST: Set clause with value");
    Builder query1 = angl.createQuery(t("area"));
    query1.update();
    query1.set(c("column_a"), v(10));
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "UPDATE area SET column_a = ?");

    io:println("TEST: Set clause with multiple columns");
    Builder query2 = angl.createQuery(t("area"));
    query2.update();
    query2.set(c("column_a"), v(10));
    query2.set(c("column_b"), v(5));
    AngelinaQuery anglQuery2 = query2.getQuery();
    test:assertEquals(anglQuery2.query, "UPDATE area SET column_a = ? , column_b = ?");

    io:println("TEST: Updating a column value to another column");
    Builder query3 = angl.createQuery(t("area"));
    query3.update();
    query3.set(c("column_a"), c("column_b"));
    AngelinaQuery anglQuery3 = query3.getQuery();
    test:assertEquals(anglQuery3.query, "UPDATE area SET column_a = column_b");
}

@test:Config {}
public function testWhereClause() {
    io:println("TEST: Only one condition");
    Builder query1 = angl.createQuery(t("area"));
    query1.select([]);
    WhereClause conditions1 = query1.where(c("column_a"), "=", v(4));
    AngelinaQuery anglQuery1 = query1.getQuery();
    test:assertEquals(anglQuery1.query, "SELECT * FROM area WHERE column_a = ?");

    io:println("TEST: Multiple conditions");
    Builder query2 = angl.createQuery(t("area"));
    query2.select([]);
    WhereClause conditions2 = query2.where(c("column_a"), "=", v(4)).and(c("column_b"), "=", v("val1"));
    AngelinaQuery anglQuery2 = query2.getQuery();
    test:assertEquals(anglQuery2.query, "SELECT * FROM area WHERE column_a = ? AND column_b = ?");

    io:println("TEST: Where clause nested condition sets");
    Builder query3 = angl.createQuery(t("area"));
    query3.select([]);
    WhereClause conditions3 = query3.where(c("column_a"), "=", v(4)).andSub(c("column_b"), "=", v(5)).or(c("column_c"), "=", v(10));
    AngelinaQuery anglQuery3 = query3.getQuery();
    test:assertEquals(anglQuery3.query, "SELECT * FROM area WHERE column_a = ? AND ( column_b = ? OR column_c = ? )");
}

@test:Config {}
public function testJoinClause() {
    io:println("TEST: Test cross join");
    Builder query1 = angl.createQuery(t("area"));
    query1.select([]);
    JoinClause joinClause = query1.joinTable(CROSS,t("shape"));
    test:assertEquals(query1.getQuery().query, "SELECT * FROM area CROSS JOIN shape");

    io:println("TEST: Test join with on clause");
    Builder query2 = angl.createQuery(t("area"));
    query2.select([]);
    OnClause onClause = query2.joinTable(INNER,t("shape")).onWhere(c("area.shape_id"),"=",c("shape.id")).and(c("area.shape_type"),"=",v(5));
    test:assertEquals(query2.getQuery().query, "SELECT * FROM area INNER JOIN shape ON area.shape_id = shape.id AND area.shape_type = ?");

    io:println("TEST: Test join with using clause");
    Builder query3 = angl.createQuery(t("area"));
    query3.select([]);
    query3.joinTable(CROSS,t("shape")).using([a(c("column_a"),"column_b")]);
    test:assertEquals(query3.getQuery().query, "SELECT * FROM area CROSS JOIN shape USING ( column_a AS column_b )");
}