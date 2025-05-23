# Mobile UX Project

## Table of Contents
- [Project Description](#project-description)
- [Planned Features](#planned-features)
- [Installation](#installation)
- [Architecture](#architecture)
- [API](#api)
- [Contributions Guidelines](#contributions-guidelines)
- [Authors](#authors)
- [License](#license)

## Project Description

Goal of this Project is to develop a mobile Chatbot for Android.

## Planned Features

- Mobile Compatibility
- Media Usage (images, videos, audios, ...)
- Custom Design and Adaptability
- Open Source?

## Installation

[Installation Guide for Flutter](https://docs.flutter.dev/get-started/install/windows/web)

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

## Architecture

The Mobile Chatbot Application is built using Flutter and Dart. The project integrates with an external API provided by the instructor for chat operations, authentication, and message handling.

## Api

### Server commands
All server commands are key-value pairs either in GET requests or in POST bodies. All GET commands are sent with a request=xyz.

### GET Requests
|**request**  |**parameters**                      |**response**|**status** |
|-------------|------------------------------------|------------|-----------|
|register     |userid, password, nickname, fullname|token	      |           |
|login        |userid, password                    |token	      |           |
|logout       |token                               |            |           |	
|deregister   |token		                           |            |           |
|fetchmessages|token <,chatid>                     |message-list|depreciated|
|getmessages  |token <,chatid>                     |message-list|           |
|getphoto     |token, photoid                      |image       |           |
|validatetoken|token                               |ok or error |           |	

### Post Requests: everything in body
|**request**  |**parameters**              |**response**|**status** |
|-------------|----------------------------|------------|-----------|
|sendmessage	|token, text <,chatid>	     |message-id  |depreciated|
|postmessage	|token, text, photo <,chatid>|message-id  |           |	

## Contributions Guidelines

### Branch Structure

The project uses the following branch structure:

- **main branch**: This branch contains the stable version of the application and is only updated with fully tested and approved features.
- **develop branch**: This branch serves as the integration branch for all new features and bug fixes. All development work should be based on this branch.

### Working with Issues
1. Creating an Issue:
- Before starting any new feature or bug fix, create a new issue in the repository. Each issue should provide a clear description of the task, enhancement, or bug to be addressed.
- You can create a new branch directly when creating the issue by using the option to "Create a branch for this issue". This ensures that each branch is directly linked to the corresponding issue.

2. Submitting Changes:
- After completing work on your branch, submit a pull request (PR) to the develop branch. In the PR description, reference the issue number and provide a summary of the changes.
- Make sure to request a review from at least one team member before merging the changes to develop.
- Once the feature has been reviewed and tested, it will be merged into the main branch after approval.

## Authors

Christian Kovacevic  (-)  

Claudio Schmidt      (clscit00@hs-esslingen.de)

Julian Hoffmann      (juhoit00@hs-esslingen.de)

## License
