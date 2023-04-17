"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[772],{3905:(e,r,t)=>{t.d(r,{Zo:()=>p,kt:()=>d});var n=t(7294);function o(e,r,t){return r in e?Object.defineProperty(e,r,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[r]=t,e}function a(e,r){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);r&&(n=n.filter((function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable}))),t.push.apply(t,n)}return t}function l(e){for(var r=1;r<arguments.length;r++){var t=null!=arguments[r]?arguments[r]:{};r%2?a(Object(t),!0).forEach((function(r){o(e,r,t[r])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):a(Object(t)).forEach((function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))}))}return e}function i(e,r){if(null==e)return{};var t,n,o=function(e,r){if(null==e)return{};var t,n,o={},a=Object.keys(e);for(n=0;n<a.length;n++)t=a[n],r.indexOf(t)>=0||(o[t]=e[t]);return o}(e,r);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(n=0;n<a.length;n++)t=a[n],r.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(o[t]=e[t])}return o}var s=n.createContext({}),c=function(e){var r=n.useContext(s),t=r;return e&&(t="function"==typeof e?e(r):l(l({},r),e)),t},p=function(e){var r=c(e.components);return n.createElement(s.Provider,{value:r},e.children)},u="mdxType",f={inlineCode:"code",wrapper:function(e){var r=e.children;return n.createElement(n.Fragment,{},r)}},v=n.forwardRef((function(e,r){var t=e.components,o=e.mdxType,a=e.originalType,s=e.parentName,p=i(e,["components","mdxType","originalType","parentName"]),u=c(t),v=o,d=u["".concat(s,".").concat(v)]||u[v]||f[v]||a;return t?n.createElement(d,l(l({ref:r},p),{},{components:t})):n.createElement(d,l({ref:r},p))}));function d(e,r){var t=arguments,o=r&&r.mdxType;if("string"==typeof e||o){var a=t.length,l=new Array(a);l[0]=v;var i={};for(var s in r)hasOwnProperty.call(r,s)&&(i[s]=r[s]);i.originalType=e,i[u]="string"==typeof e?e:o,l[1]=i;for(var c=2;c<a;c++)l[c]=t[c];return n.createElement.apply(null,l)}return n.createElement.apply(null,t)}v.displayName="MDXCreateElement"},3302:(e,r,t)=>{t.r(r),t.d(r,{contentTitle:()=>l,default:()=>u,frontMatter:()=>a,metadata:()=>i,toc:()=>s});var n=t(7462),o=(t(7294),t(3905));const a={id:"project_flavors",title:"Project Flavors",sidebar_position:3},l=void 0,i={unversionedId:"guides/project_flavors",id:"guides/project_flavors",title:"Project Flavors",description:"You can have multiple Flutter SDK versions configured per project environment or release type. FVM follows the same convention of Flutter and calls this flavors.",source:"@site/docs/guides/project_flavors.md",sourceDirName:"guides",slug:"/guides/project_flavors",permalink:"/docs/guides/project_flavors",editUrl:"https://github.com/fluttertools/fvm/edit/main/website/docs/guides/project_flavors.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{id:"project_flavors",title:"Project Flavors",sidebar_position:3},sidebar:"tutorialSidebar",previous:{title:"Configure Global Version",permalink:"/docs/guides/global_version"},next:{title:"FAQ",permalink:"/docs/guides/faq"}},s=[{value:"Pin flavor version",id:"pin-flavor-version",children:[],level:2},{value:"Switch flavors",id:"switch-flavors",children:[],level:2},{value:"View flavors",id:"view-flavors",children:[],level:2}],c={toc:s},p="wrapper";function u(e){let{components:r,...t}=e;return(0,o.kt)(p,(0,n.Z)({},c,t,{components:r,mdxType:"MDXLayout"}),(0,o.kt)("p",null,"You can have multiple Flutter SDK versions configured per project environment or release type. FVM follows the same convention of Flutter and calls this ",(0,o.kt)("inlineCode",{parentName:"p"},"flavors"),"."),(0,o.kt)("p",null,"It allows you to create the following configuration for your project."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-json"},'{\n  "flutterSdkVersion": "stable",\n  "flavors": {\n    "dev": "beta",\n    "staging": "2.0.3",\n    "production": "1.22.6"\n  }\n}\n')),(0,o.kt)("h2",{id:"pin-flavor-version"},"Pin flavor version"),(0,o.kt)("p",null,"To choose a Flutter SDK version for a specific flavor you just use the ",(0,o.kt)("inlineCode",{parentName:"p"},"use")," command."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-bash"},"fvm use {version} --flavor {flavor_name}\n")),(0,o.kt)("p",null,"This will pin ",(0,o.kt)("inlineCode",{parentName:"p"},"version")," to ",(0,o.kt)("inlineCode",{parentName:"p"},"flavor_name")),(0,o.kt)("h2",{id:"switch-flavors"},"Switch flavors"),(0,o.kt)("p",null,"Will get the version configured for the flavor and set as the project version."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-bash"},"fvm flavor {flavor_name}\n")),(0,o.kt)("h2",{id:"view-flavors"},"View flavors"),(0,o.kt)("p",null,"To list all configured flavors:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-bash"},"fvm flavor\n")),(0,o.kt)("p",null,(0,o.kt)("a",{parentName:"p",href:"https://flutter.dev/docs/deployment/flavors"},"Learn more about Flutter flavors")))}u.isMDXComponent=!0}}]);