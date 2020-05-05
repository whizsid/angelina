
function renderAlias(Alias| string alias) returns AngelinaQuery {
    if alias is string{
        return {
            query: alias,
            parameters: []
        };
    } else {
        string | Builder ref = alias.ref;

        if ref is Builder {
            AngelinaQuery query =  ref.getQuery();

            query.query = "("+query.query+") AS "+alias.alias;

            return query;
        } else {
            return {
                query: ref.concat(" AS ").concat(alias.alias),
                parameters: []
            };
        }
    }
}