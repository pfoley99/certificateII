*** Settings ***
Documentation  Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...              Creates ZIP archive of the receipts and the images.
Library  RPA.Browser  auto_close=${FALSE}
Library  RPA.Excel.Files
Library  RPA.Tables
Library  RPA.PDF
Library  RPA.FileSystem
Library  RPA.HTTP
Library  RPA.Archive

*** Variables ***
#${img_folder}=     ${OUTPUT_DIR}${/}image_files
#${pdf_folder}=     ${OUTPUT_DIR}${/}pdf_files
#${output_folder}=  ${OUTPUT_DIR}${/}output
#${orders_folder}=    ${OUTPUT_DIR}${/}receipt

*** Keywords ***
Open the intranet website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Bypass Order Form
    Click Button    OK

***Keywords***
Dowload Order Files
    Download  https://robotsparebinindustries.com/orders.csv  overwrite=True

***Keywords***
Read order Files
     ${orders}=  Read table from CSV    orders.csv  header=True
     [Return]  ${orders}

***Keywords***
Fill and submit order for one person
    [Arguments]  ${orders}
    Select From List By Value    //select[@name="head"]  ${orders}[Head]
    Click Element    //input[@value="${orders}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${orders}[Legs]
    Input Text    address  ${orders}[Address]

*** Keywords ***
Preview Button
        Click Button    id:preview

*** Keywords ***
ORDER
    Click Button       order
    Page Should Contain Element    receipt

***Keywords***
Store the receipt as a PDF file
    [Arguments]    ${orders}
    ${receipt_data}=  Get Element Attribute  id:order-completion  outerHTML
    Html To Pdf  ${receipt_data}  ${OUTPUT_DIR}${/}receipts${/}${orders}.pdf
    [return]  ${OUTPUT_DIR}${/}receipts${/}${orders}.pdf

***Keywords***
Take a Screenshot of the Robot    
    [Arguments]    ${orders}
    Screenshot  id:robot-preview-image  ${OUTPUT_DIR}${/}images${/}{orders}.png
    [return]  ${OUTPUT_DIR}${/}images${/}{orders}.png

***Keywords***
Embed
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}

***Keywords***
Submit another
    Click Button      order-another
    Bypass Order Form

***Keywords***
ZIP FILE
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}output${/}receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc    

    Create Directory    ${OUTPUT_DIR}${/}receipts
    Create Directory    ${OUTPUT_DIR}${/}images
    Create Directory    ${OUTPUT_DIR}${/}output
    
    Open the intranet website
    Bypass Order Form
    Dowload Order Files
    ${orders}=  Read order Files
        FOR  ${row}  IN  @{orders} 
            Fill and submit order for one person    ${row}
            Preview Button
            Wait Until Keyword Succeeds    12x    2 sec    ORDER 
            ${pdf}=  Store the receipt as a PDF file  ${row}[Order number]
            ${screenshot}=  Take a Screenshot of the Robot    ${row}[Order number]
            Embed    ${screenshot}    ${pdf}
            Submit another
        END  
        ZIP FILE
