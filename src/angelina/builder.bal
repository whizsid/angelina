
type Condition record {
    string operator;
    string right;
    string left;
};

public type Builder client object  {
    private string tableName;
};