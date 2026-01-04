// This script needs to be installed via Violentmonkey, see README.md

// ==UserScript==
// @name        Transparent browser fix
// @namespace   Violentmonkey Scripts
// @match       http*://*/*
// @grant       GM_addStyle
// @version     1.0
// @author      -
// @description 1/4/2026, 3:48:16 PM
// @downloadURL https://gitlab.com/xieve/dotfiles/-/raw/master/firefox/transparent-browser-fix.user.js
// ==/UserScript==

let bgColor = getComputedStyle(document.querySelector("body"))["background-color"];
const fgColor = getComputedStyle(document.querySelector("body"))["color"]
  .replace(/rgba?\((.*)\)/, "$1")
  .split(", ")
  .splice(0, 3);
const average = fgColor.reduce((a,b) => Number(a) + Number(b)) / fgColor.length;

if (average < 128 && bgColor === "rgba(0, 0, 0, 0)") {
  bgColor = "white"
}

GM_addStyle(`
  :where(html) {
    background-color: ${bgColor}
  }
`)
