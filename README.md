Welcome to AccountChain
=============================


- [Introduction](#Introduction)
- [Titles](#titles)
- [Paragraph](#paragraph)
- [List](#list)
	- [List CheckBox](#list-checkbox)
- [Link](#link)
	- [Anchor links](#anchor-links)
- [Blockquote](#blockquote)
- [Image | GIF](#image--gif)
- [Style Text](#style-text)
	- [Italic](#italic)
	- [Bold](#bold)
	- [Strikethrough](#strikethrough)
- [Code](#code)
- [Email](#email)
- [Table](#table)
	- [Table Align](#table-align)
    	- [Align Center](#align-center)
    	- [Align Left](#align-left)
    	- [Align Right](#align-right)
- [Escape Characters](#escape-characters)
- [Emoji](#emoji)
- [Shields Badges](#Shields-Badges)
- [Markdown Editor](#markdown-editor)
- [Some links for more in depth learning](#some-links-for-more-in-depth-learning)



# Introduction
Welcome to *AccountChain©*!

*AccountChain©* is a blockchain-based customer loyalty platform where transactions of non-monetized loyalty points are securely processed and immutably recorded in a permissioned ledger environment. The result is a **decentral**, **fully transparent**, and **fraud-protected** real-time accounting system. Moreover, it includes a cryptographically secured redemption process of loyalty points, mitigating risks of counterfeited occurrence of financial liabilities. AccountChain© is based on Hyperledger Fabric Blockchain and operates in a private permissioned ledger environment. 

<img width="1039" alt="rename_screenshot" src="images/3D-mockup.jpg">

## Project Description

Based on the Request for Solution of TopPharm, the main task of this project was to examine the question whether and to what extent blockchain technology can help to improve customer loyalty programs with regard to real-time data integrity, transparency, and security. In this respect, we have evaluated whether blockchain technology in fact delivers a value added compared to a traditional database approach. The result of our assessment clearly underlines that there are significant advantages for all previously mentioned criteria. We have therefore conceptualized *AccountChain©* which is a decentral, fully transparent and fraud-protected loyalty platform, embedded in a permissioned ledger Hyperledger Fabric blockchain environment. It ensures data security through cryptographically signed transaction history and helps to increase efficiency by automating accounting processes. The concept further includes a special focus on a fraud-protected voucher redemption process, applying cryptographic hash functions to mitigate the risk of counterfeited occurrence of financial liabilities in the network. To summarize, the *AccountChain©* ecosystem creates transparency, data security, and increased efficiency further leading to cost savings, for customer loyalty networks consisting of independent legal entities who do not necessarily trust each other but pursue the same business goals. 

## Technical Documentation

This technical documentation mainly contains the explanation to the smart contract. Additionally, the 2 mock-up user interfaces are also shortly described. 
- The Smart Contract code **AccountChain.sol** written in solidity, can be found on the GitHub Page and it has been uploaded through Adam as well.
- The Client User Interface [AccountChain App](https://xd.adobe.com/view/b63ae9ae-8d0c-4d6c-b447-ee5eade2a5d9-e369/?fullscreen&hints=off)
- The Pharmacy User Interface [AccountChain WebApp](https://public.tableau.com/profile/dominik.merz#!/vizhome/shared/354DZRXPK)

## Chaincode Description

Chaincode is the Smart Contract in Hyperledger, which plays a central role in the *AccountChain©* application. It documents transactions, manages promotions, calculates tax and current accounts, and cryptographically verifies the actual existence and validity of vouchers during the redemption process. The main functions contained in our Chaincode are explained in the following.

### addTransaction

Everything starts with a purchase in one of the branches in the loyalty network. This function documents transactions on the blockchain, therefore denoting the first step in a loyalty point’s journey. 

The information contained in a transaction is the client ID, the respective pharmacy ID, a list of purchased products and a unique transaction ID. 
```
    struct transaction {
        uint pharmacyID;
        uint clientID;
        mapping (uint => product) productSold;
        uint point;
        uint pointValue; 
        uint transactionTime;
    }
```
All transactions are stored in a mapping <transactionList> using the unique transaction ID as the key. 
 ```
mapping (uint => transaction) transactionList;
```   
addTransaction further calls the [calcPoint](#-calcPoint) and calcPointValue functions to calculate the points and point values related to the transaction and to store this information as part of a transaction in transactionList. 
    The attribute PointValue is introduced to record the value of points from the issuing pharmacy’s point of view. Let’s elaborate briefly on this. If points issued are not combined with any promotion, a point has a (default) value of CHF 0.01. On the other side, let’s assume that there exists a x20 multi-point promotion. In this case, from a pharmacy’s point of view, one point has a value equal to CHF 0.0005 since the promotion is paid by the producer, not by pharmacies. In other words, the fraction of additional points issued here (19/20) must be charged to third parties. For the pharmacy itself, the points issued in this transaction therefore only have a value (to be paid) of CHF 0.01/20 = CHF 0.0005. Additionally, data related to multi-point promotions is stored in promotionList.  After calculating the number of points and their respective point value, the addTransaction function updates the PointRecordList and therefore the client’s point account. As described in section 5.7, an event will be triggered to create a clean voucher code in an off-chain application as soon as a client has reached a point balance of 500. Subsequently, the Chaincode function IssueVoucher is called to record the existence and attributes of the respective voucher. 
    
[Go to Real Cool Heading section](##-rename-this-repository-to-publish-your-site)

## calcPoint

**GitHub Pages** is a free and easy way to create a website using the code that lives in your GitHub repositories. You can use GitHub Pages to build a portfolio of your work, create a personal website, or share a fun project that you coded with the world. GitHub Pages is automatically enabled in this repository, but when you create new repositories in the future, the steps to launch a GitHub Pages website will be slightly different.

[Learn more about GitHub Pages](https://pages.github.com/)

## Rename this repository to publish your site

We've already set-up a GitHub Pages website for you, based on your personal username. This repository is called `hello-world`, but you'll rename it to: `username.github.io`, to match your website's URL address. If the first part of the repository doesn’t exactly match your username, it won’t work, so make sure to get it right.

Let's get started! To update this repository’s name, click the `Settings` tab on this page. This will take you to your repository’s settings page. 

![repo-settings-image](https://user-images.githubusercontent.com/18093541/63130482-99e6ad80-bf88-11e9-99a1-d3cf1660b47e.png)

Under the **Repository Name** heading, type: `username.github.io`, where username is your username on GitHub. Then click **Rename**—and that’s it. When you’re done, click your repository name or browser’s back button to return to this page.

<img width="1039" alt="rename_screenshot" src="https://user-images.githubusercontent.com/18093541/63129466-956cc580-bf85-11e9-92d8-b028dd483fa5.png">

Once you click **Rename**, your website will automatically be published at: https://your-username.github.io/. The HTML file—called `index.html`—is rendered as the home page and you'll be making changes to this file in the next step.

Congratulations! You just launched your first GitHub Pages website. It's now live to share with the entire world

## Making your first edit

When you make any change to any file in your project, you’re making a **commit**. If you fix a typo, update a filename, or edit your code, you can add it to GitHub as a commit. Your commits represent your project’s entire history—and they’re all saved in your project’s repository.

With each commit, you have the opportunity to write a **commit message**, a short, meaningful comment describing the change you’re making to a file. So you always know exactly what changed, no matter when you return to a commit.

## Practice: Customize your first GitHub website by writing HTML code

Want to edit the site you just published? Let’s practice commits by introducing yourself in your `index.html` file. Don’t worry about getting it right the first time—you can always build on your introduction later.

Let’s start with this template:

```
<p>Hello World! I’m [username]. This is my website!</p>
```

To add your introduction, copy our template and click the edit pencil icon at the top right hand corner of the `index.html` file.

<img width="997" alt="edit-this-file" src="https://user-images.githubusercontent.com/18093541/63131820-0794d880-bf8d-11e9-8b3d-c096355e9389.png">


Delete this placeholder line:

```
<p>Welcome to your first GitHub Pages website!</p>
```

Then, paste the template to line 15 and fill in the blanks.

<img width="1032" alt="edit-githuboctocat-index" src="https://user-images.githubusercontent.com/18093541/63132339-c3a2d300-bf8e-11e9-8222-59c2702f6c42.png">


When you’re done, scroll down to the `Commit changes` section near the bottom of the edit page. Add a short message explaining your change, like "Add my introduction", then click `Commit changes`.


<img width="1030" alt="add-my-username" src="https://user-images.githubusercontent.com/18093541/63131801-efbd5480-bf8c-11e9-9806-89273f027d16.png">

Once you click `Commit changes`, your changes will automatically be published on your GitHub Pages website. Refresh the page to see your new changes live in action.

:tada: You just made your first commit! :tada:

## Extra Credit: Keep on building!

Change the placeholder Octocat gif on your GitHub Pages website by [creating your own personal Octocat emoji](https://myoctocat.com/build-your-octocat/) or [choose a different Octocat gif from our logo library here](https://octodex.github.com/). Add that image to line 12 of your `index.html` file, in place of the `<img src=` link.

Want to add even more code and fun styles to your GitHub Pages website? [Follow these instructions](https://github.com/github/personal-website) to build a fully-fledged static website.

![octocat](./images/create-octocat.png)

## Everything you need to know about GitHub

Getting started is the hardest part. If there’s anything you’d like to know as you get started with GitHub, try searching [GitHub Help](https://help.github.com). Our documentation has tutorials on everything from changing your repository settings to configuring GitHub from your command line.

Getting started with Markdown
=============================


- [Getting started with Markdown](#getting-started-with-markdown)
- [Titles](#titles)
- [Paragraph](#paragraph)
- [List](#list)
	- [List CheckBox](#list-checkbox)
- [Link](#link)
	- [Anchor links](#anchor-links)
- [Blockquote](#blockquote)
- [Image | GIF](#image--gif)
- [Style Text](#style-text)
	- [Italic](#italic)
	- [Bold](#bold)
	- [Strikethrough](#strikethrough)
- [Code](#code)
- [Email](#email)
- [Table](#table)
	- [Table Align](#table-align)
    	- [Align Center](#align-center)
    	- [Align Left](#align-left)
    	- [Align Right](#align-right)
- [Escape Characters](#escape-characters)
- [Emoji](#emoji)
- [Shields Badges](#Shields-Badges)
- [Markdown Editor](#markdown-editor)
- [Some links for more in depth learning](#some-links-for-more-in-depth-learning)

----------------------------------

# Titles 

### Title 1
### Title 2

	Title 1
	========================
	Title 2 
	------------------------

# Title 1
## Title 2
### Title 3
#### Title 4
##### Title 5
###### Title 6

    # Title 1
    ## Title 2
    ### Title 3    
    #### Title 4
    ##### Title 5
    ###### Title 6    

# Paragraph
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit. Phasellus eleifend egestas diam, id tincidunt arcu dictum quis. Pellentesque eu dui tempus, tempus massa sed, eleifend tortor. Donec in sem in erat iaculis tincidunt. Fusce condimentum hendrerit turpis nec vehicula. Aliquam finibus nisi vel eros lobortis dictum. Etiam congue tortor libero, quis faucibus ligula gravida a. Suspendisse non pulvinar nisl. Sed malesuada, felis vitae consequat gravida, dui ligula suscipit ligula, nec elementum nulla sem vel dolor. Vivamus augue elit, venenatis non lorem in, volutpat placerat turpis. Nullam et libero at eros vulputate auctor. Duis sed pharetra lacus. Sed egestas ligula vitae libero aliquet, ac imperdiet est ullamcorper. Sed dapibus sem tempus eros dignissim, ac suscipit lectus dapibus. Proin sagittis diam vel urna volutpat, vel ullamcorper urna lobortis. Suspendisse potenti.

Nulla varius risus sapien, nec fringilla massa facilisis sed. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc vel ornare erat, eget rhoncus lectus. Suspendisse interdum scelerisque molestie. Aliquam convallis consectetur lorem ut consectetur. Nullam massa libero, cursus et porta ac, consequat eget nibh. Sed faucibus nisl augue, non viverra justo sagittis venenatis.

    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit. 
    
    Phasellus eleifend egestas diam, id tincidunt arcu dictum quis.

# List 
* Item 1;
	* Item 1.1;
* Item 2;
	* Item 2.1;
	* Item 2.2;
* Item 3
	* Item 3.1;
		* Item 3.1.1;
    
>      * Item 1;
>	      * Item 1.1;
>	    * Item 2;
>	     * Item 2.1;
>	     * Item 2.2;
>	    * Item 3
>		   * Item 3.1;
>			  * Item 3.1.1;

## List CheckBox

 - [ ] Item A
 - [x] Item B
 - [x] Item C
 
>     - [ ] Item A
>     - [x] Item B
>     - [x] Item C


# Link
[Google](https://www.google.com) - _Google | Youtube | Gmail | Maps | PlayStore | GoogleDrive_

[Youtube](https://www.youtube.com) - _Enjoy videos and music you love, upload original content, and share it with friends, family, and the world on YouTube._

[GitHub](https://github.com/fefong/markdown_readme#getting-started-with-markdown) - _Project_

		[Google](https://www.google.com) - _Google | Youtube | Gmail | Maps | PlayStore | GoogleDrive_

## Anchor links

[Markdown - Summary](#Getting-started-with-Markdown)

[Markdown - Markdown Editor](#Markdown-Editor)

		[Markdown - Link](#Link)

# Blockquote
> Lebenslangerschicksalsschatz: Lifelong Treasure of Destiny

    > Lebenslangerschicksalsschatz: Lifelong Treasure of Destiny 

# Image | GIF
![myImage](https://media.giphy.com/media/XRB1uf2F9bGOA/giphy.gif)
    
    ![myImage](https://media.giphy.com/media/XRB1uf2F9bGOA/giphy.gif)
    
See more [Markdown Extras - Image Align](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#image-align)    

# Style Text
### Italic

*Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.*

     *Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.*

### Bold
**Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.**

    **Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.**
    
### Strikethrough
~~strikethrough text~~

    ~~strikethrough text~~
    
# Code

```java
public static void main(String[] args) {
	//TODO
}
```

>   \`\`\`java <br>
>   public static void main(String[] args) {<br>
>	    //TODO<br>
>	}<br>
>   \`\`\`<br>

See more [Markdown Extras - Style Text](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#style-text)

# Email
<email@email.com>

    <email@email.com>

# Table

|Column 1|Column 2|Column 3|
|---|---|---|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|---|---|---|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Table Align

## Align Center

|Column 1|Column 2|Column 3|
|:---:|:---:|:---:|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|:---:|:---:|:---:|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Align Left

|Column 1|Column 2|Column 3|
|:---|:---|:---|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|:---|:---|:---|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Align Right

|Column 1|Column 2|Column 3|
|---:|---:|---:|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|---:|---:|---:|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

See more [Markdown Extras - Table](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table)
* [Rownspan](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table---rowspan)
* [Colspan](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table---colspan)

# Escape Characters

```
\   backslash
`   backtick
*   asterisk
_   underscore
{}  curly braces
[]  square brackets
()  parentheses
#   hash mark
+   plus sign
-   minus sign (hyphen)
.   dot
!   exclamation mark
```

# Emoji

* [Emoji](emoji.md#emoji);
	* [People](emoji.md#people) - (:blush: ; :hushed: ; :shit:);
	* [Nature](emoji.md#nature) - (:sunny: ; :snowman: ; :dog:);
	* [Objects](emoji.md#objects) - (:file_folder: ; :computer: ; :bell:);
	* [Places](emoji.md#places) - (:rainbow: ; :warning: ; :statue_of_liberty:);
	* [Symbols](emoji.md#symbols) - (:cancer: ; :x: ; :shipit:);
* [Kaomoji](emoji.md#kaomoji);
* [Special-Symbols](emoji.md#special-symbols);
	

# Shields Badges

:warning: _We are not responsible for this site_

See more: [https://shields.io/](https://shields.io/)

[![GitHub forks](https://img.shields.io/github/forks/fefong/markdown_readme)](https://github.com/fefong/markdown_readme/network)
![Markdown](https://img.shields.io/badge/markdown-project-red)

# Markdown Editor

[StackEdit](https://stackedit.io) - _StackEdit’s Markdown syntax highlighting is unique. The refined text formatting of the editor helps you visualize the final rendering of your files._

# Some links for more in depth learning

:page_facing_up: [Markdown Extras](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#markdown---extras)

:page_facing_up: [Wikipedia - Markdown](https://pt.wikipedia.org/wiki/Markdown)

:page_facing_up: [Oficial](https://daringfireball.net/projects/markdown/)



