CREATE OR REPLACE function utils.safe_cast(text,anyelement)
returns anyelement
language plpgsql as $$
begin
    $0 := $1;
    return $0;
    exception when others then
        return $2;
end; $$;