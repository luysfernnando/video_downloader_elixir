# Instruções para Copilot e Contribuidores

Este projeto Elixir/Phoenix foi estruturado de forma **limpa, moderna e funcional**, inspirado nos padrões do React (componentização, simplicidade) e do Laravel (organização de pastas).

## Estrutura de Pastas

- `lib/controllers/` — Controllers da aplicação (sempre com sufixo `_controller`)
- `lib/pages/` — Páginas (cada página em sua própria pasta, templates `.heex`)
- `lib/components/` — Componentes reutilizáveis (estilo React)
- `lib/layouts/` — Layouts globais
- `lib/core/` — Arquivos core do Phoenix (Application, Router, Endpoint, etc.)
- `lib/web.ex` — Centraliza macros e helpers para uso em todo o projeto

## Criação de Novas Páginas

> **Nunca crie páginas manualmente!**
>
> Sempre utilize os componentes DaisyUI já instalados e configurados neste projeto. Isso garante consistência visual, responsividade e facilidade de manutenção.

- Crie uma pasta para a página em `lib/pages/NOME_DA_PAGINA/`.
- Adicione o template principal `.heex` dentro dessa pasta, utilizando apenas componentes DaisyUI e componentes reutilizáveis do projeto.
- No arquivo `lib/pages/pages.ex`, adicione um módulo assim:

```elixir
  defmodule NomeDaPagina do
    @moduledoc "Descrição da página"
    use VideoDownloaderElixirWeb, :page
  end
```
- Para usar uma pasta customizada:
```elixir
  defmodule Settings do
    @moduledoc "Configurações"
    use VideoDownloaderElixirWeb, {:page, folder: "config"}
  end
```

## Criação de Novos Componentes

- Adicione componentes em `lib/components/`.
- Sempre utilize e componha com DaisyUI e siga o padrão de componentização do Phoenix, mantendo a simplicidade e reutilização como no React.

## Controllers

- Todos os controllers devem ser criados em `lib/controllers/` e **devem obrigatoriamente terminar com o sufixo `_controller`**.
- Exemplo: `page_controller.ex`, `user_controller.ex`.

## Princípios Gerais

- **Evite arquivos e módulos desnecessários**. Centralize e simplifique sempre que possível.
- **Organização e clareza** são prioridade: cada parte do projeto tem seu lugar definido.
- **Componentização**: tudo que for reutilizável deve ser um componente.
- **Páginas**: cada página é um módulo simples, com template separado e sempre usando DaisyUI.
- **Layouts**: mantenha layouts globais em `lib/layouts/`.

> **Sempre siga essa estrutura limpa e funcional ao criar novas páginas, componentes, layouts ou qualquer parte do projeto!**
