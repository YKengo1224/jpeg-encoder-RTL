# vivado project template

verilog,systemverilogとVivadoを用いたRTL設計のプロジェクトのテンプレートです。

## Make コマンド
[Make] or [Make help]をコマンドラインで入力するとMakeのサブコマンド一覧
が表示されます。詳しくはそちらを確認してください。

対応しているシミュレータはIcurus Verilog Xceliumです.

## ディレクトリ構成

```
rtl         --- 合成するモジュール用
tb          --- テストベンチ格納用
tcl         --- vivadoをバッチモードで実行する際のtclファイル
vitis-work  --- vitisを使用する際のディレクトリ
vivado-work --- vivadoを使用する際のディレクトリ
sim_log     --- シミュレーション時のログを格納
sim_work    --- シミュレーション時の生成ファイルを格納
wave        --- 波形ファイルを格納
```

```
.
├── README.md
├── Makefile
├── sim.mk                     //シミュレーション用Makefile
├── rtl
│   └── add.v                  //テンプレートファイル
├── tb
│   └── Tb_Template.sv         //テンプレートファイル
├── tcl
│   ├── create_proj.tcl        //vivadoプロジェクト生成
│   └── generate_bitstream.tcl //ビットストリーム生成
└── vitis-work
```