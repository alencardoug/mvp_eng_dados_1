{#
    Histórico de atributos do agente — SCD tipo 2 (ADR-0017).

    A equipe é o que classifica o chamado numa análise. Um agente que muda de
    equipe não pode reescrever a equipe que atendeu o chamado do ano passado —
    seria a métrica de uma equipe migrando para outra sem que nada tivesse
    acontecido no atendimento.

    Nome, e-mail e data de contratação ficam de fora de propósito: descrevem a
    pessoa, não classificam o chamado. Correção de cadastro não é fato novo.
#}

{% snapshot scd_support_agent %}

{{
    config(
        unique_key='support_agent_id',
        strategy='check',
        check_cols=[
            'agent_team',
            'agent_is_active',
            'is_deleted',
        ],
    )
}}

select * from {{ ref('support_agents') }}

{% endsnapshot %}
