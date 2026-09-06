-- Uma captura por execução: proíbe misturar gerações entre tabelas.
select source_system
from {{ ref('legacy_records') }}
group by source_system
having count(distinct snapshot_id) <> 1
