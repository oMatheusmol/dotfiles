---
description: Lê em voz alta (via Piper TTS) a sua última resposta nesta conversa
---

Pegue o texto da sua última resposta nesta conversa (a que veio antes deste comando) e:

1. Limpe o texto pra soar bem falado:
   - Caminhos de arquivo completos (ex: `/dev/test/test/arquivo.ts`) → fale só o nome
     do arquivo (`arquivo.ts`), não o caminho inteiro
   - Blocos de código extensos → não leia código literalmente, resuma em uma frase
     curta o que ele faz
   - Sintaxe markdown (`**negrito**`, `` `código inline` ``, links `[texto](url)`,
     `#` de headers, `-`/`*` de listas) → remova a sintaxe, mantenha só o texto
   - URLs → substitua por algo como "um link", não leia a URL character por character
2. Detecte se o texto limpo é predominantemente português ou inglês.
3. Salve o texto limpo num arquivo temporário e rode:
   ```
   ~/.local/bin/speak.sh --lang pt arquivo_temp.txt
   ```
   (troque `pt` por `en` se detectar que o texto é majoritariamente inglês)
4. Não precisa mostrar o texto limpo pro usuário nem explicar o que fez — só confirme
   rapidamente que está lendo em voz alta.

Lembre-se: `~/.local/bin/mpvctl {pause|resume|toggle|stop|restart|speed up|speed down}`
controla a reprodução em andamento, caso o usuário peça pra pausar/parar/mudar
velocidade depois de iniciar.
