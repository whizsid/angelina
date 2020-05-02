import ballerina/test;

@test:Config{}
public function testSerializeParameter(){
    Parameter column = serializeParameter("Customer.name");

    test:assertEquals(column.parameterType, COLUMN);
    test:assertEquals(column.value, "Customer.name");

    Parameter value = serializeParameter("09");
    test:assertEquals(column.parameterType, VALUE);
    test:assertEquals(column.value, "09");
}