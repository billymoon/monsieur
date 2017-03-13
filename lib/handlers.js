export default function (program) {
  let beautify = require('js-beautify')

  // pre-process languages
  let marked = require('marked')
  let stylus = require('stylus')
  let less = require('less')
  let sass = require('node-sass')
  let slm = require('slm')
  let xml2json = require('xml2json')

  let handlers = {
    js: {
      // only require babel if it is going to be used - takes about 1 second to load!
      process: str => program.babel ? require('babel-core').transform(str, {presets: ['env', 'react']}).code : str,
      chain: 'js'
    },
    xml: {
      process: str => JSON.stringify(JSON.parse(xml2json.toJson(str)), null, 4),
      chain: 'json'
    },
    svg: {
      process: str => JSON.stringify(JSON.parse(xml2json.toJson(str)), null, 4),
      chain: 'json'
    },
    less: {
      process: (str, file) => {
        let out = null
        less.render(str, {
          filename: file,
          syncImport: true
        }, function (e, compiled) {
          out = compiled
        })
        return out.css
      },
      chain: 'css'
    },
    stylus: {
      process: str => stylus.render(str),
      chain: 'css'
    },
    scss: {
      process: str => sass.renderSync({data: str}).css,
      chain: 'css'
    },
    sass: {
      process: str => sass.renderSync({data: str, indentedSyntax: true}).css,
      chain: 'css'
    },
    markdown: {
      process: str => beautify.html(marked(str)),
      chain: 'html'
    },
    slim: {
      process: str => beautify.html(slm.render(str), {indent_size: 4}),
      chain: 'html'
    }
  }

  handlers.md = handlers.markdown
  handlers.slm = handlers.slim
  handlers.styl = handlers.stylus

  slm.template.registerEmbeddedFunction('markdown', handlers.markdown.process)
  slm.template.registerEmbeddedFunction('less', str => `<style type="text/css">${handlers.less.process(str)}</style>`)
  slm.template.registerEmbeddedFunction('stylus', str => `<style type="text/css">${handlers.stylus.process(str)}</style>`)
  slm.template.registerEmbeddedFunction('scss', str => `<style type="text/css">${handlers.scss.process(str)}</style>`)
  slm.template.registerEmbeddedFunction('sass', str => `<style type="text/css">${handlers.sass.process(str)}</style>`)

  return handlers
}
