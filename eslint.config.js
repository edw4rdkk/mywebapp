module.exports = [
  {
    files: ["src/**/*.js"],
    rules: {
      "no-unused-vars": "error",
      "no-undef": "error",
      "no-console": "off",
      semi: ["error", "always"],
      eqeqeq: "warn",
    },
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        require: "readonly",
        module: "readonly",
        exports: "readonly",
        process: "readonly",
        console: "readonly",
        __dirname: "readonly",
      },
    },
  },
];
