# zed
Zed is a command line tool for editing text using Perl Regular Expressions


## Samples

`$ zed "s/foo/bar" "foo"`

Pode ser usado para testar expressão regular de substituição (s///, tr///).

`$ cat foo.txt | zed "s/foo/bar/g"`

Envia para saída padrão todo conteúdo do arquivo foo.txt com palavra `foo` trocada para `bar`.

`$ zed res.txt foo.txt`

Executa todas as expressões regulares do arquivo res.txt sobre o arquivo foo.txt.

`$ zed "1, s/foo/bar" foo.txt`

Modifica a primeira ocorrência de `foo` para `bar` na segunda linha do arquivo foo.txt.

`$ zed "0..5, s/foo/bar/g" foo.txt`

Substitue toda ocorrência de `foo` para `bar` da primeira linha à quinta.

`$ cat foo.txt | zed "1.., d"`

Remove todas as linhas a partir da segunda linha.

`$ zed "2..5, d" foo.txt`

Remove as linhas 3-6 do arquivo foo.txt

`$ zed "/foo/, d" foo.txt`

Remove todas as linhas em que a expressão regular casar.

`$ zed "1..5, /foo/, d" foo.txt`

Remove as linhas 2-6 do arquivo foo.txt que casar com expressão regular.

`$ free -m | zed "0..1,d;-1,d;s/\D+(\d+)\s+(\d+)/[\$1] [\$2]/g"`

Destaca o valor de buffers/cache.

`$ ls -1 | zed "~/\d/,d"`

Remove as linhas que não casam com a expressão regular.
