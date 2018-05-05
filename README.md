# React 模式

> [React in patterns](https://github.com/krasimir/react-in-patterns) 中文版

:book: 介绍 [React](https://facebook.github.io/react/) 开发的设计模式和技术的免费开源书籍。

## 书

* [在线](https://sangka.github.io/react-in-patterns-cn)
* [PDF](https://github.com/SangKa/react-in-patterns-cn/raw/gh-pages/ebook/React模式.pdf)
* [Mobi](https://github.com/SangKa/react-in-patterns-cn/raw/gh-pages/ebook/React模式.mobi)
* [ePub](https://github.com/SangKa/react-in-patterns-cn/raw/gh-pages/ebook/React模式.epub)

![React in patterns cover](./book/cover_small.jpg)

## 目录

* [简介](./book/chapter-1/README.md)

### 基础

* [组件通讯](./book/chapter-2/README.md)
  * [输入](./book/chapter-2/README.md#输入)
  * [输出](./book/chapter-2/README.md#输出)
* [事件处理](./book/chapter-3/README.md)
* [组合](./book/chapter-4/README.md)
  * [使用 React children API](./book/chapter-4/README.md#使用-react-children-api)
  * [将 child 作为 prop 传入](./book/chapter-4/README.md#将-child-作为-prop-传入)
  * [高阶组件](./book/chapter-4/README.md#高阶组件)
  * [将函数作为 children 传入和 render prop](./book/chapter-4/README.md#将函数作为-children-传入和-render-prop)
* [受控输入和非受控输入](./book/chapter-5/README.md)
* [展示型组件和容器型组件](./book/chapter-6/README.md) 

### 数据流

* [单向数据流](./book/chapter-7/README.md)
* [Flux](./book/chapter-8/README.md)
  * [Flux 架构及其主要特点](./book/chapter-8/README.md#flux-架构及其主要特点)
  * [实现 Flux 架构](./book/chapter-8/README.md#实现-flux-架构)
* [Redux](./book/chapter-9/README.md)
  * [Redux 架构及其主要特点](./book/chapter-9/README.md#redux-架构及其主要特点)
  * [使用 Redux 的简单计数器应用](./book/chapter-9/README.md#使用-redux-的简单计数器应用)

### 其他

* [依赖注入](./book/chapter-10/README.md)
  * [使用 React context (16.3 之前的版本)](./book/chapter-10/README.md#使用-react-context-163-之前的版本)
  * [使用 React context (16.3 及之后的版本)](./book/chapter-10/README.md#使用-react-context-163-及之后的版本)
  * [使用模块系统](./book/chapter-10/README.md#使用模块系统)
* [组件样式](./book/chapter-11/README.md)
  * [经典 CSS 类](./book/chapter-11/README.md#经典-css-类)
  * [内联样式](./book/chapter-11/README.md#内联样式)
  * [CSS 模块](./book/chapter-11/README.md#css-模块)
  * [Styled-components](./book/chapter-11/README.md#styled-components)
* [集成第三方库](./book/chapter-12/README.md)

## 源码

书中所使用的代码全部在 [这里](./code) 。

## 其他资源

* [React 设计原则](https://facebook.github.io/react/contributing/design-principles.html)
* [Airbnb React/JSX 风格指南](https://github.com/airbnb/javascript/tree/master/react)
* [Planning Center Online 所使用的 React 模式](https://github.com/planningcenter/react-patterns)
* [Michael Chan 所写的 React 模式](http://reactpatterns.com/)
* [React 的模式、技术、小贴士和技巧](https://github.com/vasanthk/react-bits)

## 构建本书

`yarn install && yarn build`

*要生成电子书，需要先安装 [calibre](http://calibre-ebook.com/about) ，然后执行 `ln -s /Applications/calibre.app/Contents/MacOS/ebook-convert /usr/local/bin/` 。*
