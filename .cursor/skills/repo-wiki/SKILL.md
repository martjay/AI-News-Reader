---
name: repo-wiki
description: 使用 Repo Wiki 知识引擎查询项目架构、模块实现与团队知识。当用户询问项目结构、模块依赖、代码规范时使用。
---

# Repo Wiki 知识引擎

本项目使用 Repo Wiki 插件自动生成结构化文档。

## 知识位置

- Wiki 文档: `.qoder/repowiki/{lang}/wiki/`
- Knowledge Cards: `.qoder/repowiki/{lang}/cards/`
- Memory: `.qoder/repowiki/{lang}/memory/`
- 配置文件: `.qoder/repowiki/wiki_plan.yaml`

## 使用方式

1. 架构/实现问题优先查阅 Wiki 和 Knowledge Cards
2. 使用 `@repowiki` 获取项目知识上下文
3. 使用 `/knowledge` 命令修改或补充知识
4. 人工修改的内容受保护，不会被自动更新覆盖
