﻿SELECT 
  (element->>'date')::timestamp AS DATE,
  extract (hours from ((element->>'start')::timestamp)) as start,
  extract (minutes from ((element->>'start')::timestamp)) as start,
  (element->>'stop')::timestamp as stop,
  element->>'resource' AS resource
from json_array_elements ((
  select DATA AS doc from incoming.snapshot
)) as element

