import ballerinax/java.jdbc;

function renderAlias(Alias| string alias) returns AngelinaQuery {
   
    if alias is string{
        return {
            query: alias,
            parameters: []
        };
    } else {
        string | Builder | jdbc: Param ref = alias.ref;

        if ref is Builder {
            AngelinaQuery ang_query =  ref.getQuery();

            string query = ang_query.query;
            jdbc:Param[] parameters = ang_query.parameters;

            return {
                query: "( "+query+" ) AS "+alias.alias,
                parameters: parameters
            };
            
        } else if ref is string {
            string select_column = concat(ref,"AS");
            select_column = concat(select_column,alias.alias);
            return {
                query: select_column,
                parameters: []
            };
        } else {
            return {
                query: "? AS "+alias.alias,
                parameters: [ref]
            };
        }
    }
}