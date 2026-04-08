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
      <h3 class="text-muted"><a href="https://seamlessaccess.org/"><img alt="SeamlessAccess Homepage" src="https://seamlessaccess.org/images/logo.svg" width="200"></a></h3>
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


