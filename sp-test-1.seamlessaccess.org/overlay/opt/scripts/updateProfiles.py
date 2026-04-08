#!/usr/bin/env python3
import urllib.request, urllib.parse
import json
from datetime import datetime as dt

def printHeader(f):
    print('''<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <title>SeamlessAccess</title>
  <link href="//release-check.swamid.se/fontawesome/css/fontawesome.min.css" rel="stylesheet">
  <link href="//release-check.swamid.se/fontawesome/css/solid.min.css" rel="stylesheet">
  <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css"
    integrity="sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N" crossorigin="anonymous">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="SeamlessAccess.org is a service designed to help foster a more streamlined online access experience when using scholarly collaboration tools, information resources, and shared research infrastructure." />
  <meta property="og:title" content="SeamlessAccess.org - true Single Sign On" />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="https://seamlessaccess.org" />
  <meta property="og:image" content="https://seamlessaccess.org/images/logo.svg" />
  <meta property="og:description" content="SeamlessAccess.org is a service designed to help foster a more streamlined online access experience when using scholarly collaboration tools, information resources, and shared research infrastructure. Your users will be able to sign in using their preferred sign in credentials, and will not be bothered for them again for all SeamlessAccess-enabled sites." />
  <meta name="twitter:card" content="summary" />
  <meta name="twitter:site" content="@seamlessaccess" />
  <meta name="twitter:creator" content="@seamlessaccess" />
  <link rel="icon" href="https://seamlessaccess.org/favicon.png">
  <style>
/* Space out content a bit */
body {
 padding-top: 20px;
 padding-bottom: 20px;
}

/* Everything gets side spacing for mobile first views */
.header {
 padding-right: 15px;
 padding-left: 15px;
}

/* Custom page header */
.header {
 border-bottom: 1px solid #e5e5e5;
}
/* Make the masthead heading the same height as the navigation */
.header h3 {
 padding-bottom: 19px;
 margin-top: 0;
 margin-bottom: 0;
 line-height: 40px;
}
.left {
 float:left;
}
.clear {
 clear: both
}

.text-truncate {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    display: inline-block;
    max-width: 100%;
}

/* color for fontawesome icons */
.fa-check {
 color: green;
}

.fa-exclamation-triangle {
 color: orange;
}

.fa-exclamation {
 color: red;
}

/* Customize container */
@media (min-width: 768px) {
.container {
 max-width: 1230px;
}
}
.container-narrow > hr {
 margin: 30px 0;
}

/* Responsive: Portrait tablets and up */
@media screen and (min-width: 768px) {
/* Remove the padding we set earlier */
.header {
 padding-right: 0;
 padding-left: 0;
}
/* Space out the masthead */
.header {
 margin-bottom: 30px;
}
}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <nav>
        <ul class="nav nav-pills float-right">
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.org/services/" class="nav-link">The Service</a></li>
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.org/stakeholders/" class="nav-link">Stakeholders</a></li>
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.atlassian.net/wiki/spaces/DOCUMENTAT/overview" class="nav-link">Documentation</a></li>
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.org/learning-center/" class="nav-link">Learning Center</a></li>
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.org/about/" class="nav-link">About</a></li>
          <li role="presentation" class="nav-item"><a href="https://seamlessaccess.org/posts/" class="nav-link">Blog</a></li>
        </ul>
      </nav>
      <h3 class="text-muted"><a href="https://seamlessaccess.org/">
        <svg role="graphics-document" title="SVG Image" desc="" alt=""   version="1.1" id="Logo" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1013.8 496.3" style="enable-background:new 0 0 1013.8 496.3;" xml:space="preserve" preserveAspectRatio="xMinYMid meet" width="200px">
        <style type="text/css">
          .st0{fill:#216E93;}
        </style>
        <path class="st0" d="M400.5,244.6c-8.3,0-17.7-4.3-24.9-10.6l-13.2,15.7c10.3,9.4,23.7,14.6,37.6,14.7c24.2,0,38.2-14.6,38.2-31.4
          c0-14.3-7.7-22.6-20.1-27.6l-12.9-5.2c-8.9-3.5-15.5-5.8-15.5-12c0-5.8,5-9.1,12.9-9.1c8,0,14.4,2.8,21.1,7.9l11.6-14.5
          c-8.7-8.5-20.4-13.3-32.6-13.3c-21.1,0-36.1,13.4-36.1,30.2c0,14.7,10,23.4,20.5,27.7l13.2,5.6c8.9,3.7,14.6,5.7,14.6,12.1
          C414.8,240.8,410.1,244.6,400.5,244.6z"/>
        <path class="st0" d="M516.7,220.5c0-21.1-10.9-37.1-32.9-37.1c-18.6,0-36.4,15.4-36.4,40.5c0,25.6,17.1,40.5,39.1,40.5
          c9.8-0.2,19.3-3.2,27.4-8.7l-7.6-13.8c-5.6,3.3-10.9,5.1-16.7,5.1c-10.3,0-18-5.1-20-16.3h46.2C516.4,227.3,516.7,223.9,516.7,220.5
          z M469.3,215.5c1.6-9.8,7.8-14.6,15-14.6c9.1,0,12.8,6.1,12.8,14.6H469.3z"/>
        <path class="st0" d="M524.8,241.1c0,13,8.9,23.3,23,23.3c8.7,0,16-4.1,22.5-9.8h0.6l1.6,7.9h18.7v-44.1c0-23.7-10.9-34.9-30.7-34.9
          c-12.1,0-23.2,4.2-33,10.2l8.1,15c7.5-4.2,14-7,20.4-7c8.4,0,11.8,4.4,12.2,11.2C537.7,216,524.8,224.8,524.8,241.1z M568.3,226.6
          v13.5c-4.1,4-7.5,6.6-12.7,6.6c-5.4,0-8.9-2.4-8.9-7.4C546.7,233.5,552,228.8,568.3,226.6z"/>
        <path class="st0" d="M674.7,262.5v-52.1c4.9-5.1,9.3-7.5,13.1-7.5c6.5,0,9.5,3.5,9.5,14.6v45h22.9v-47.9c0-19.3-7.5-31.2-24.2-31.2
          c-10.2,0-17.5,5.9-24.2,13c-3.9-8.3-10.5-13-21.3-13c-10.1,0-17.1,5.4-23.4,11.8h-0.6l-1.6-9.9h-18.7v77.2h22.9v-52.1
          c4.9-5.1,9.3-7.5,13.1-7.5c6.5,0,9.5,3.5,9.5,14.6v45H674.7z"/>
        <path class="st0" d="M754.4,264.4c5.2,0,9-0.8,11.5-1.9l-2.7-16.8c-0.9,0.2-1.9,0.3-2.8,0.3c-1.9,0-4.1-1.6-4.1-6.5v-86h-22.9v85.1
          C733.3,254.2,738.7,264.4,754.4,264.4z"/>
        <path class="st0" d="M832.1,241.9c-5.6,3.3-10.9,5.1-16.7,5.1c-10.3,0-18-5.1-20-16.3h46.2c0.7-3.3,1-6.7,1-10.1
          c0-21.1-10.9-37.1-32.9-37.1c-18.6,0-36.4,15.4-36.4,40.5c0,25.6,17.1,40.5,39.1,40.5c9.8-0.2,19.3-3.2,27.4-8.7L832.1,241.9z
          M810.1,200.9c9.1,0,12.8,6.1,12.8,14.6h-27.8C796.6,205.7,802.9,200.9,810.1,200.9z"/>
        <path class="st0" d="M880,247.5c-6.5,0-12.9-2.8-19.9-8.1l-10.3,14.3c7.8,6.4,19.5,10.8,29.6,10.8c20.7,0,31.7-10.9,31.7-24.9
          c0-14.1-11-19.6-20.8-23.2c-8-2.9-15.2-4.8-15.2-9.7c0-3.9,2.9-6.2,8.8-6.2c5.3,0,10.8,2.6,16.3,6.6l10.2-13.7
          c-6.6-5-15.4-9.8-27.2-9.8c-17.8,0-29.5,9.8-29.5,24.2c0,12.8,11,19,20.4,22.7c8,3.1,15.6,5.4,15.6,10.5
          C889.7,244.9,886.8,247.5,880,247.5z"/>
        <path class="st0" d="M948,247.5c-6.5,0-12.9-2.8-19.9-8.1l-10.3,14.3c7.8,6.4,19.5,10.8,29.7,10.8c20.7,0,31.7-10.9,31.7-24.9
          c0-14.1-11-19.6-20.8-23.2c-8-2.9-15.2-4.8-15.2-9.7c0-3.9,2.9-6.2,8.8-6.2c5.3,0,10.8,2.6,16.3,6.6l10.2-13.7
          c-6.6-5-15.4-9.8-27.2-9.8c-17.8,0-29.5,9.8-29.5,24.2c0,12.8,11,19,20.4,22.7c7.9,3.1,15.6,5.4,15.6,10.5
          C957.7,244.9,954.8,247.5,948,247.5z"/>
        <path class="st0" d="M387.8,284.9L356,386.4h23.5l6.3-24.2h30.9l6.2,24.2h24.3l-31.9-101.4H387.8z M390.3,344.4l2.4-9.4
          c2.8-10.1,5.5-22,8-32.7h0.6c2.7,10.6,5.4,22.6,8.2,32.7l2.4,9.4H390.3z"/>
        <path class="st0" d="M490,369.8c-9.9,0-17.3-8.6-17.3-22s7.1-22,18.1-22c3.7,0,6.8,1.4,10.5,4.6l10.8-14.7
          c-6.2-5.5-14.3-8.4-22.6-8.3c-21.3,0-40.2,14.8-40.2,40.5c0,25.7,16.6,40.5,38.2,40.5c8.4,0,17.9-2.6,25.5-9.2l-9-15
          C499.9,367.3,495.1,369.8,490,369.8z"/>
        <path class="st0" d="M556.6,369.8c-9.9,0-17.3-8.6-17.3-22s7.1-22,18.1-22c3.7,0,6.8,1.4,10.5,4.6l10.8-14.7
          c-6.2-5.5-14.3-8.4-22.6-8.3c-21.3,0-40.2,14.8-40.2,40.5c0,25.7,16.6,40.5,38.2,40.5c8.4,0,17.9-2.6,25.5-9.2l-9-15
          C566.6,367.3,561.7,369.8,556.6,369.8z"/>
        <path class="st0" d="M618.9,307.3c-18.6,0-36.4,15.4-36.4,40.5c0,25.6,17.1,40.5,39.1,40.5c9.8-0.2,19.3-3.2,27.4-8.7l-7.5-13.8
          c-5.6,3.3-10.9,5.1-16.7,5.1c-10.3,0-18-5.1-20-16.3h46.2c0.6-3.3,1-6.7,0.9-10.1C651.8,323.3,640.9,307.3,618.9,307.3z
          M604.4,339.3c1.6-9.8,7.8-14.6,15-14.6c9.1,0,12.8,6.1,12.8,14.6H604.4z"/>
        <path class="st0" d="M700.4,340.1c-8-2.9-15.2-4.8-15.2-9.7c0-3.9,2.9-6.2,8.8-6.2c5.3,0,10.8,2.6,16.3,6.6l10.2-13.7
          c-6.6-5-15.4-9.8-27.2-9.8c-17.8,0-29.5,9.8-29.5,24.2c0,12.8,11,19,20.4,22.7c7.9,3.1,15.6,5.4,15.6,10.5c0,4-2.9,6.6-9.8,6.6
          c-6.5,0-12.9-2.8-19.9-8.1l-10.3,14.3c7.8,6.4,19.5,10.8,29.6,10.8c20.7,0,31.7-10.9,31.7-24.9C721.2,349.2,710.2,343.7,700.4,340.1
          z"/>
        <path class="st0" d="M768.4,340.1c-8-2.9-15.2-4.8-15.2-9.7c0-3.9,2.9-6.2,8.8-6.2c5.3,0,10.8,2.6,16.3,6.6l10.2-13.7
          c-6.6-5-15.4-9.8-27.2-9.8c-17.8,0-29.5,9.8-29.5,24.2c0,12.8,11,19,20.4,22.7c7.9,3.1,15.6,5.4,15.6,10.5c0,4-2.9,6.6-9.8,6.6
          c-6.5,0-12.9-2.8-19.9-8.1l-10.3,14.3c7.8,6.4,19.5,10.8,29.7,10.8c20.7,0,31.7-10.9,31.7-24.9C789.2,349.2,778.2,343.7,768.4,340.1
          z"/>
        <path class="st0" d="M805,374.1c-3.4,0-6.6,2.7-6.6,7.2c-0.2,3.6,2.7,6.7,6.3,6.9c3.6,0.2,6.7-2.7,6.9-6.3c0-0.2,0-0.4,0-0.6
          C811.6,376.8,808.5,374.1,805,374.1z"/>
        <path class="st0" d="M854.7,309.8c-18,0-33.6,14.4-33.6,39.4c0,24.7,15.6,39.1,33.6,39.1s33.6-14.4,33.6-39.1
          C888.2,324.1,872.6,309.8,854.7,309.8z M854.7,382.2c-15.1,0-26.3-13.3-26.3-33c0-19.7,11.2-33.3,26.3-33.3
          c15.1,0,26.3,13.6,26.3,33.3S869.8,382.2,854.7,382.2z"/>
        <path class="st0" d="M908.8,325.6h-0.3l-0.7-13.9h-5.8v74.7h6.9v-50.8c5.7-14.1,13.7-19.2,20.4-19.2c2.3-0.1,4.6,0.4,6.8,1.2
          l1.6-6.2c-2.3-1.1-4.8-1.6-7.4-1.6C921.2,309.8,913.9,316.4,908.8,325.6z"/>
        <path class="st0" d="M982.3,380h-16c-11.1,0-14.3-4.3-14.3-9.7c0-5,2.8-8.2,6.1-10.8c3.8,2.1,8,3.2,12.4,3.2
          c14.6,0,26.1-11.1,26.1-26.4c0-7.9-3.4-14.6-8.2-18.7h17.4v-5.9h-25.3c-3.2-1.3-6.5-1.9-9.9-1.9c-14.6,0-26.3,11-26.3,26.4
          c0.1,7.9,3.5,15.3,9.5,20.5v0.6c-3.3,2.3-8.2,7.1-8.2,13.8c-0.1,4.9,2.4,9.5,6.6,12v0.6c-6.9,4.9-11.2,11.5-11.2,18
          c0,12.6,11.9,20.7,30.7,20.7c21.5,0,35.3-12.4,35.3-25.3C1007,385.3,999.1,380,982.3,380z M951.2,336.1c0-12.8,8.7-20.7,19.3-20.7
          s19.3,8.1,19.3,20.7c0,12.5-9,21-19.3,21S951.2,348.6,951.2,336.1L951.2,336.1z M972.4,416.8c-15.8,0-24.8-6.4-24.8-15.8
          c0-5.3,2.9-11,9.8-15.7c3,0.7,6.1,1.1,9.2,1.2h16c11.3,0,17.3,3.1,17.3,11.4C999.9,407.3,989.2,416.8,972.4,416.8L972.4,416.8z"/>
        <path class="st0" d="M47.4,193.8h239c7.6,0.1,14.3-4.7,16.7-11.9c1.9-7.1-0.5-14.7-6.7-19L176.8,77.2c-6.2-4.3-14.3-4.3-20,0
          L37.4,162.8c-4.3,3.3-7.1,8.1-7.1,13.8c0,9.4,7.6,17.1,17,17.1C47.3,193.8,47.3,193.8,47.4,193.8z M166.9,112.4l66.2,47.1H100.7
          L166.9,112.4z"/>
        <polygon class="st0" points="146.3,306.8 146.8,234 104.4,214.9 104.4,325.8 "/>
        <polygon class="st0" points="187.5,306.8 186.9,234 229.3,214.9 229.3,325.8 "/>
        <path class="st0" d="M320.8,361.6h-14.4v-14.4c0-5-4-9-9-9h-13.5V227.2c0-11-8.9-19.9-19.9-19.9c-11,0-19.9,8.9-19.9,19.9l0,0v111.1
          H89.7V227.2c0-11-8.9-19.9-19.9-19.9c-11,0-19.9,8.9-19.9,19.9v111H36.4c-5,0-9,4-9,9v14.4H13c-5,0-9,4-9,9v15.6h325.7v-15.5
          C329.7,365.7,325.7,361.6,320.8,361.6z"/>
        </svg>
      </a></h3>
    </div>''', file=f)
    print(f'''    <div class="row">
      <div class="col">List created : {dt.today().strftime('%Y-%m-%d %H:%M:%S')}</div>
    </div>
    <div class="table-responsive">
      <table id="profiles-table" class="table table-striped table-bordered">
        <thead>
          <tr>
            <th>entityID</th>
            <th>Profile(s)</th>
          </tr>
        </thead>''', file=f)

def printFooter(f):
    print(f'''  </div><!-- End container-->
  <!-- jQuery first, then Popper.js, then Bootstrap JS -->
  <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js"
    integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj"
    crossorigin="anonymous">
  </script>
  <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"
    integrity="sha384-9/reFTGAW83EW2RDu2S0VKaIzap3H66lZH81PoYlFhbGU+6BZp6G7niu735Sk7lN"
    crossorigin="anonymous">
  </script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js"
    integrity="sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+"
    crossorigin="anonymous">
  </script>
</body>
</html>''', file=f)

'''
  Main 
'''
with urllib.request.urlopen("https://a-1.thiss.io/metadata.json") as url:
    data = json.load(url)
    entityList = {}
    for entity in data:
        if 'discovery_responses' in entity:
            entityList[entity["entity_id"]] = entity["discovery_responses"][0]

def sortKey(e):
        return e['entityID']

counter = 0
with urllib.request.urlopen("https://a-1.thiss.io/metadata_sp.json") as url:
    f = open('/var/www/demo/profiles/index.html','w')
    printHeader(f)
    data = json.load(url)
    data.sort(key=sortKey)
    for entity in data:
        if entity['entityID'] in entityList:
            testBase='https://use.thiss.io/ds/?entityID=' + urllib.parse.quote_plus(entity['entityID']) + '&return=' + urllib.parse.quote_plus(entityList[entity['entityID']]) + '&trustProfile='
        else:
            testBase='https://use.thiss.io/ds/?entityID=' + urllib.parse.quote_plus(entity['entityID']) + '&trustProfile='
        tests=''
        for profile in entity['profiles'].keys():
            tests += "\n" + f'                <br><a href="{testBase}{profile}">Test profile {profile}</a><br>'
        profileList=", ".join(entity['profiles'].keys())
        print(f'''        <tr>
          <td>
            <a data-toggle="collapse" href="#entity-{counter}" aria-expanded="0" aria-controls="entity-{counter}">{entity['entityID']}</a>
            <div class="collapse multi-collapse" id="entity-{counter}">{tests}
            </div><!-- end collapse -->
          </td>
          <td>
            <div class="show collapse multi-collapse" id="entity-{counter}">
              {profileList}
            </div><!-- end collapse -->
            <div class="collapse multi-collapse" id="entity-{counter}">
              <pre>{json.dumps(entity['profiles'], indent=2)}
              </pre>
            </div><!-- end collapse -->
          </td>
        </tr>''', file=f)
        counter += 1
    print(f'''      </table>
    </div>''', file=f)
    print(f'''    <div class="row">
      <div class="col">Number of entities with profile(s) = {counter}</div>
    </div>''', file=f)
    printFooter(f)


