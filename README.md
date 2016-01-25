<!-- README.md is generated from README.Rmd. Please edit that file -->
wakatimer: UNOFFICIAL WakaTime Plugin for RStudio
-------------------------------------------------

Currently, test cheking **Mac OS X only**. Please report other plaform result and [issues](https://github.com/uribo/wakatimer/issues/new).

💻 Requirement and Setup
-----------------------

1.  [Create WakaTime accont](https://wakatime.com/signup).
2.  Configure your own [API key](https://wakatime.com/settings).
3.  [Registry application](https://wakatime.com/apps) and to get an OAuth 2.0 client token to use wakatimer.

Then, Install package from GitHub repository.

``` r
devtools::install_github("uribo/wakatimer")
```

🔰 How to Use
------------

Loading package and run `write_scole()` function to authorize.

``` r
library(wakatimer)
write_scole()
# Waiting for authentication in browser...
# Press Esc/Ctrl + C to abort
# Authentication complete.
```

Next, wakatime api key and app id set to R global environment.

``` r
Sys.setenv("WAKATIME_KEY" = "<your api key>")
Sys.setenv("WAKATIME_ID" = "<application id>")
Sys.setenv("WAKATIME_SECRET" = "<application secret>")
```

I recommend these variables are add to .Rprofile such as below.

``` r
# .Rprofile
Sys.setenv(
  WAKATIME_KEY     = "<your api key>",
  WAKATIME_ID      = "<application id>",
  WAKATIME_SECRET  = "<application secret>"
)
```

**Use like you normally do and your time will record by log.**

``` r
q()
```

Current sessions modificate file information will sent to WakaTime!! Visit <https://wakatime.com> to see your logged time. Also, you can confirm in RStudio :)

``` r
# project,language,branch,is_write,is_debugging,lines
req <- wakatimer:::wt_api(resource = "heartbeats", 
                   key = Sys.getenv("WAKATIME_KEY"), 
                   param = list(date = format(Sys.Date(), "%m/%d/%Y"), time = "time", "entity"))
req$data %>% head() %>% knitr::kable(format = "markdown")
```

<table style="width:156%;">
<colgroup>
<col width="77%" />
<col width="52%" />
<col width="16%" />
<col width="8%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">entity</th>
<th align="left">id</th>
<th align="right">time</th>
<th align="left">type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">~/git/r_pkg/wakatimer/vignettes/wakatimer-workflow.Rmd</td>
<td align="left">02d27d37-d228-49f4-9067-2ee7260fc14d</td>
<td align="right">1453734664</td>
<td align="left">file</td>
</tr>
<tr class="even">
<td align="left">~/git/r_pkg/wakatimer/R/zzz.R</td>
<td align="left">207cd092-251b-40d4-b1c4-f26a296f298e</td>
<td align="right">1453742043</td>
<td align="left">file</td>
</tr>
<tr class="odd">
<td align="left">~/git/r_pkg/wakatimer/R/zzz.R</td>
<td align="left">94d89fae-3407-4ee0-a920-8cce3f375038</td>
<td align="right">1453742827</td>
<td align="left">file</td>
</tr>
<tr class="even">
<td align="left">~/git/r_pkg/wakatimer/.Rprofile</td>
<td align="left">61bc6270-3b9b-4f9e-8241-9a1a8b2b5f08</td>
<td align="right">1453745367</td>
<td align="left">file</td>
</tr>
<tr class="odd">
<td align="left">~/git/r_pkg/wakatimer/R/wt_sync.R</td>
<td align="left">53b85419-fc44-4fc8-beef-f7d6f94aaa17</td>
<td align="right">1453746391</td>
<td align="left">file</td>
</tr>
<tr class="even">
<td align="left">~/git/r_pkg/wakatimer/README.Rmd</td>
<td align="left">71a5c819-6299-4287-b3cd-55f79d872ab7</td>
<td align="right">1453747159</td>
<td align="left">file</td>
</tr>
</tbody>
</table>

### Recommend

Do not forget loading package.

``` r
# .Rprofile
.First <- function() {
  # invalid when rmarkdown render
  if(interactive()) {
    suppressMessages(library(wakatimer))
    wakatimer::write_scope()
  }
}
```

🗿 Milestone
-----------

0.1.0

-   \[x\] セッション中のファイル変更を自動的に記録、POSTするまで
-   \[x\] lineno, cursorpos パラメータの追加

0.2.0

-   \[\] テストファイルの整備
-   \[\] 継続的インテグレーションが実行できるようにする
-   \[\] **`{rstudioaddin}`**との連携
-   \[\] .wakatime.cfg に管理対象外のファイルを追加する関数
-   \[\] 管理対象のファイルはエラー扱いにする
-   \[\] APIを使った可視化
-   \[\] 全APIへの対応
-   \[\] Shiny Widget への対応
-   \[\] vignettes, documentの充実
-   \[\] オフラインでの記録と再接続時の投稿（instフォルダ内へのファイル、データベース保存？）
-   \[\] Mac以外のOSへの対応

🚨 Current Issues
----------------

多分、正常に動作ているだろうという不安さ。
