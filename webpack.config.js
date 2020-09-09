const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const dist = 'dist';
const outputDir = path.join(__dirname, dist);
const webpack = require('webpack')
const isProd = process.env.NODE_ENV === 'production';

new HtmlWebpackPlugin({
    favicon: "./favicon.ico"
})


module.exports = {
  entry: './src/gui/client/Index.bs.js',
  mode: isProd ? 'production' : 'development',
  output: {
    path: path.resolve(__dirname, dist),
    filename: isProd ? 'index.[contenthash].js' : 'dist/index.[contenthash].js'
  },
  plugins: [
      new HtmlWebpackPlugin({
          template: './src/gui/client/static/index.html',
          favicon: './src/gui/client/static/favicon.ico',
      }),
  ],
  devServer: {
    compress: true,
    contentBase: outputDir,
    port: process.env.PORT || 8000,
    historyApiFallback: true
  },
    module: {
        rules: [
            {
                test: /\.css$/i,
                use: ['style-loader', 'css-loader'],
            },
            {
                test: /\.s[ac]ss$/,
                use: [
                    'style-loader',
                    "css-loader",
                    "sass-loader"
                ]
            },
            {
                test: /\.(woff(2)?|ttf|eot|svg|png)(\?v=\d+\.\d+\.\d+)?$/,
                use: [
                    {
                        loader: 'file-loader',
                        options: {
                            name: '[name].[ext]',
                            outputPath: 'fonts/'
                        }
                    }
                ]
            }
        ],
    },
};
