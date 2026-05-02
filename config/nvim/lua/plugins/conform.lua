return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            c = { "clang_format" },
            cpp = { "clang_format" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            css = {},
            html = { "prettier" },
            json = { "prettier" },
            markdown = { "prettier" },
            python = { "prettier" },
        },
    },
}
