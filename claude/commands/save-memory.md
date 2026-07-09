---
description: Resume esta conversa num arquivo markdown dentro de .memory/ no projeto atual
---

Resuma esta conversa inteira num arquivo markdown, seguindo estes passos:

1. Descubra a data de hoje (data real do sistema, não invente).
2. Se a pasta `.memory/` não existir no diretório atual, crie-a.
3. Escolha um slug curto em kebab-case que descreva o assunto principal da conversa
   (ex: `fix-feature-antigo-212`, `nova-feature-auth`). Se o usuário passou um
   argumento em `$ARGUMENTS`, use-o como base do slug em vez de inventar um.
4. Salve o resumo em `.memory/DD.MM.YYYY-<slug>.md` (data no formato dia.mes.ano).
5. O conteúdo do resumo deve ter, em markdown:
   - O que foi feito/decidido nesta conversa (resumo objetivo, não o histórico completo)
   - Decisões técnicas importantes e o porquê (não óbvias a partir do código sozinho)
   - Coisas aprendidas sobre o projeto/domínio que valem ser lembradas depois
   - Itens pendentes ou próximos passos, se houver
6. NÃO rode `/clear` nem sugira apagar a conversa automaticamente — apenas salve o
   arquivo e informe o caminho completo onde foi salvo, para o usuário conferir o
   nome e local antes de decidir limpar o contexto manualmente.

Seja objetivo: isso é um resumo pra consulta futura, não uma transcrição.
