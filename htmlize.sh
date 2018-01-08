#!/usr/bin/env bash
export LC_CTYPE=C LANG=C

export GRIPURL=$(pwd)
echo "CACHE_DIRECTORY = '$(pwd)/githubassets'" >> ~/.grip/settings.py
for f in *.md; do grip --export $f ; done
# for f in *.html; do sed -i '' "s?$GRIPURL/??g" $f; done

find . -name '*.html' -print0 | xargs -0 sed -i '' 's/.md/.html/g'


##### MANCA trasformazinoe nome file README.md in index.html
##### MANCA trasformazione nomi files.... da: step-01-componenti-principali.html ----> rotilio-thermo-step-01-componenti-principali.html

##### MANCA questo head da inserire nelle pagine html generate
<head>
  	<meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=device-width">
    <meta http-equiv="refresh" content="0; url=http://techmakers.io/formaker/termostatoopensource/rotilio-thermo-termostato-open-source.html">

    <!-- Meta -->
    <meta content="Rotilio thermo - termostato open source" property="og:title">
    <meta content="Questo è un tutorial per costruire un termostato open source, personalizzabile, economico, intelligente. Troverete tutte le componenti e i passaggi per costruirlo, scrivere il firwmare e l'APP Mobile" name="description">

    <script async="" src="https://www.google-analytics.com/analytics.js"></script>
    <script async="" charset="utf-8" src="https://v2.zopim.com/?4mWCOhTZkvtJza92XbR7FDRazylxzBJu" type="text/javascript"></script><script src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>


    <!--Start of Zendesk Chat Script-->
    <script type="text/javascript">
        window.$zopim || (function (d, s) {
            var z = $zopim = function (c) {
                z._.push(c)
            }, $ = z.s =
                    d.createElement(s), e = d.getElementsByTagName(s)[0];
            z.set = function (o) {
                z.set._.push(o)
            };
            z._ = [];
            z.set._ = [];
            $.async = !0;
            $.setAttribute('charset', 'utf-8');
            $.src = 'https://v2.zopim.com/?4mWCOhTZkvtJza92XbR7FDRazylxzBJu';
            z.t = +new Date;
            $.type = 'text/javascript';
            e.parentNode.insertBefore($, e)
        })(document, 'script');
    </script>
    <!--End of Zendesk Chat Script-->
    <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-101546095-1', 'auto');
        ga('send', 'pageview');

    </script>
</head>
