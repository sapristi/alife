import path from 'path'
const __dirname = path.dirname(new URL(import.meta.url).pathname)

const config = {
  entry: './src/index.mjs',
  output: {
    filename: 'cola-cytoscape.mjs',
    path: path.resolve(__dirname, 'dist'),
    library: {
      type: "module",
    },
  },
  optimization: {
    minimize: false
  },
  experiments: {
    outputModule: true,
  },
};

export default config
