// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const {themes} = require('prism-react-renderer');
const darkTheme = themes.dracula;
const oceanicTheme = themes.oceanicNext;

/** @type {import('@docusaurus/types').Config} */
const config = {
  themes: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        docsRouteBasePath: '/docs',
        blogDir: 'blog',
        indexPages: true,
      },
    ],
  ],
  title: 'SoCMake',
  tagline: 'Build System for Hardware',
  favicon: 'img/SoCMakeLogo3.svg',

  // Set the production url of your site here
  url: 'https://hep-soc.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  // Overridable via DOCS_BASE_URL so PR preview builds can be served from a
  // sub-path (e.g. /SoCMake/pr-preview/pr-123/) without touching this file.
  baseUrl: process.env.DOCS_BASE_URL || '/SoCMake/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'socmake', // Usually your GitHub org/user name.
  projectName: 'socmake', // Usually your repo name.

  onBrokenLinks: 'throw',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        },
        blog: {
          path: './blog',
          routeBasePath: 'blog',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'SoCMake',
        logo: {
          alt: 'My Site Logo',
          src: 'img/SoCMakeLogo3.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            type: 'docSidebar',
            sidebarId: 'apiSidebar',
            position: 'left',
            label: 'API Reference',
          },
          {to: 'blog', label: 'Blog', position: 'left'},
          {
            href: 'https://github.com/HEP-SoC/SoCMake',
            label: 'Github',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Documentation',
                to: '/docs/intro',
              },
              {
                label: 'API Reference',
                to: '/docs/api',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/HEP-SoC/SoCMake',
              },
            ],
          },
        ],
        copyright: `Copyright CERN © ${new Date().getFullYear()}, Built with Docusaurus.`,
      },
      prism: {
        theme: oceanicTheme,
        darkTheme: darkTheme,
        additionalLanguages: ['cmake', 'verilog', 'bash', 'diff', 'json'],
      },
    }),
};

module.exports = config;
