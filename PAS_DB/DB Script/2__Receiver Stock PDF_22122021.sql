
UPDATE EmailTemplateType SET EmailTemplateType='Receiver Stock PDF' WHERE EmailTemplateTypeId=64;

Insert Into EmailTemplate Values ('Receiver Stock PDF','<!DOCTYPE html>
<html>
  <head>
        <style>
          @page {
            size: auto;
            margin: 0mm;
          }

          @media print {
            @page {
              margin-top: 0;
              margin-bottom: 0;
            }

            @page {
              size: landscape
            }
          }

          span {
            /* font-weight: normal; */
            font-family: Tahoma, Arial, sans-serif;
            font-size: 10.5px !important;
            font-weight: 700;
          }

          table {
            font-size: 12px !important;
            width: 100%;
          }

          table thead {
            background: #808080;
          }

          table,
          thead,
          td {
            border: 1px solid black;
            border-collapse: collapse;
          }

          table,
          thead,
          th {
            border: 1px solid black;
            border-collapse: collapse;
          }

          .border-none {
            border: none;
          }

		  .parttabletd {      background: #c7c6c6 !important; text-align: left;      color: #000 !important;      -webkit-print-color-adjust: exact; border-bottom:1px solid black; border-right:1px solid black;   }

          table thead tr th {
            //   background: #0d57b0 !important;        padding: 5px!important;color: #fff;letter-spacing: 0.3px;font-weight:bold;        font-family: Tahoma, Arial, sans-serif;         font-size: 10.5px;text-transform: capitalize; z-index: 1;}     table tbody{   overflow-y: auto; max-height: 500px;  }    table tbody tr td{ vertical-align: top;background: #fff;       padding: 2px;line-height: 22px;       height:22px;color: #333;      //  border-right:1px solid black !important;      font-family: Tahoma, Arial, sans-serif;font-weight;normal;      font-size: 10.5px !important;max-width:100%; letter-spacing: 0.1px;border:0}    h4{padding: 5px; display: inline-block; font-size: 14px; font-weight: normal; width: 100%; margin: 0;}        .very-first-block {position: relative; height:auto;border-right:1px solid black; min-height: 1px; float: left;padding-right: 2px;padding-left: 2px;      width: 50%;}    .first-block-name{margin-right: 20px}     .first-block-sold-to {      position: relative;      min-height: 82px;      height: auto;      float: left;      padding-bottom:5px;      padding-right: 2px;      border-right: 1px solid black;      background: #fff;      width: 100%;      margin-top:-2px         }        .first-block-ship-to {      position: relative;      min-height: 80px;      padding-bottom:5px;      height: auto;      padding-right: 2px;      border-right: 1px solid black;      background: #fff;      width: 100%;        }        .first-block-sold {      position: relative;      min-height: 120px;      height:auto;      float: left;      border-right:1px solid black;      padding-right: 2px;      padding-left: 2px;      margin-left:-1px;      width: 50%;    }        .first-block-ship {      position: relative;      min-height: 1px;      float: right;      padding-right: 2px;           width: 49%;    }        .address-block {      position: relative;      min-height: 1px;      float: left;      height:auto;      padding-right: 2px;      // border: 1px solid black;      width: 100%;      padding-left: 2px;    }        .first-block-address {      margin-right: 20px;      text-align: left    }            .second-block {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      width: 42%;      height:auto;      padding-left: 2px;      box-sizing: border-box;    }        .second-block-div {      margin: 2px 0;      position: relative;      //display: flex;      min-height: 1px;      height:auto           width: 100%;    }    .label{      font-weight:500;    }        .second-block-label {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      padding-left: 2px;      font-family: Tahoma, Arial, sans-serif;          font-size: 10.5px !important;                width: 38.33333333%;          text-transform: capitalize;          margin-bottom: 0;          text-align: left;    }        .clear {      clear: both;    }        .form-div {      // top: 6px;      position: relative;      font-weight: normal;      font-size:12.5;      font-family: Tahoma, Arial, sans-serif;      // margin-top: 10px;         }    span {      font-weight: normal;      font-size: 10.5px !important;  }        .image {      border: 1px solid #000;      // padding: 5px;      width: 100%;      display: block;    }        .logo-block {      margin: auto;      text-align: center    }        .pdf-block {      width: 800px;      margin: auto;      font-family: Tahoma, Arial, sans-serif;      font-weight:normal;      border: 1px solid #ccc;      padding: 25px 15px;    }        .picked-by {      position: relative;      float: left;      width: 48%;      font-family: Tahoma, Arial, sans-serif;      font-size: 10.5px !important;      font-weight: 700;    }        .confirmed-by {      position: relative;      float: right;      width: 48%;      font-family: Tahoma, Arial, sans-serif;      font-size: 10.5px !important;      font-weight: 700;    }        .first-part {      position: relative;      display: inline;      float: left;      width: 50%    }        .seond-part {      position: relative;      display: flex;      float: right;      width: 24%    }        .input-field-border {      width: 88px;      border-radius: 0px !important;      border: none;      border-bottom: 1px solid black;    }        .border-transparent {      border-block-color: white;    }        .pick-ticket-header {      border: 1px solid black;      text-align: center;      background: #0d57b0 !important;      color: #fff !important;      -webkit-print-color-adjust: exact;    }        .first-block-label {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      padding-left: 2px;      // width: 38.33333333%;      font-size:10.5px !important;          font-family: Tahoma, Arial, sans-serif;             text-transform: capitalize;      margin-bottom: 0;      text-align: left;    }        .very-first-block {      position: relative;      min-height: 129px;      float: left;      height:auto;     border-right:1px solid black;      padding-right: 2px;      padding-left: 2px;      width: 57% !important;    }        .logo {      padding-top: 10px;          // height:70px;          // width:220px;          height:auto;          max-width:100%;          padding-bottom:10px;    }        .sold-block-div {      //margin: 1px 0;      position: relative;      display: inline-block;      min-height: 1px;      width: 100%;    }        .ship-block-div {      //margin: 1px 0;      position: relative;      display: inline-block;      min-height: 1px;      width: 100%;    }    .first-block-sold-bottom{      border-bottom: 1px solid black;          position:relative;          min-height:1px;          height:auto;          width:100%;          float:left;            // margin-top: -2px;           // min-height: 120px;    }        .parttable th {      background: #c7c6c6 !important; text-align: left;      color: #000 !important;      -webkit-print-color-adjust: exact;    }    .border-bottom{      border-bottom:1px solid black !important;    }    .table-margins{          margin-top:-1px;margin-left:0px        }    .invoice-border{      border-bottom: 1px solid;          position:relative;            // min-height: 119px;            min-height:1px;            height: auto;            width:100%;          float:left;}                                                  .capitalletter{text-transform: uppercase !important;}         
        </style>
      </head>
      <body>
        <!--<h4 style="border-bottom:0px solid">Speed Quote Exclusion</h4>-->
        <form id="" name="" action="#" method="post" onsubmit="return false;">
          <div class="image">
            <div style="padding: 0; margin: 0; border-right: none;">
              <form id="" class="form-div" name="" action="#" method="post" onsubmit="return false;">
                <!-- <div class="logo-block"><img src="http://design.poweraerosuites.com/image/logo.png" width="130" /></div><div class="clear"></div><hr /> -->
                <div class="col-sm-12 invoice-border">
                  <div class="very-first-block col-sm-8">
                    <div class="col-sm-12 address-block" style="width:100%;">
                      <div class="col-sm-6" style="width:48%; float: left;">
                        <img class="logo" src="##ManagementLogo##" />
                      </div>
                      <div class="col-sm-6" style="width:50%; padding-top:5px; margin-left:20px; float: right;">
                        <div class="col-sm-12 first-block-name">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##CompanyName##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##Address1##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##City##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##StateOrProvince##, ##PostalCode##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##Country##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##PhoneNo##</label>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="second-block col-sm-4">
                    <h3 style="margin-top: 1px; margin-bottom: -2px; margin-left: -2px; border-bottom: 1px solid black !important; text-align: center; width: 102%;"> Receiving Stock PO</h3>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''r Num</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>-</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''d Date:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>-</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">PO/RO Num:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##PurchaseOrderNumber##</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Date:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##OpenDate##</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''d By:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##PreparedBy##</label>
                    </div>
                    <div class="second-block-div" style="margin-top:30px">
                      <label class="col-sm-6 second-block-label" style="width:48%">Print Date/Time:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##Printdate##</label>
                    </div>
                  </div>
                </div>
                <div class="col-sm-12"></div>
                <div class="clear"></div>
                <div class="col-sm-12"> ##exclusionparts## </div>
                <!--<div style="height:100px"> &nbsp;</div>-->
              </form>
            </div>
          </div>
        </form>
      </body>
    </div>
</html>',1,'AUTO SCRIPT','AUTO SCRIPT',GETDATE(),GETDATE(),1,0,'',(SELECT TOP 1 EmailTemplateTypeId FROM EmailTemplateType where EmailTemplateType='Receiver Stock PDF'),'',1,GETDATE());

Insert Into EmailTemplate Values ('Receiver Stock PDF','<!DOCTYPE html>
<html>
  <head>
        <style>
          @page {
            size: auto;
            margin: 0mm;
          }

          @media print {
            @page {
              margin-top: 0;
              margin-bottom: 0;
            }

            @page {
              size: landscape
            }
          }

          span {
            /* font-weight: normal; */
            font-family: Tahoma, Arial, sans-serif;
            font-size: 10.5px !important;
            font-weight: 700;
          }

          table {
            font-size: 12px !important;
            width: 100%;
          }

          table thead {
            background: #808080;
          }

          table,
          thead,
          td {
            border: 1px solid black;
            border-collapse: collapse;
          }

          table,
          thead,
          th {
            border: 1px solid black;
            border-collapse: collapse;
          }

          .border-none {
            border: none;
          }

		  .parttabletd {      background: #c7c6c6 !important; text-align: left;      color: #000 !important;      -webkit-print-color-adjust: exact; border-bottom:1px solid black; border-right:1px solid black;   }

          table thead tr th {
            //   background: #0d57b0 !important;        padding: 5px!important;color: #fff;letter-spacing: 0.3px;font-weight:bold;        font-family: Tahoma, Arial, sans-serif;         font-size: 10.5px;text-transform: capitalize; z-index: 1;}     table tbody{   overflow-y: auto; max-height: 500px;  }    table tbody tr td{ vertical-align: top;background: #fff;       padding: 2px;line-height: 22px;       height:22px;color: #333;      //  border-right:1px solid black !important;      font-family: Tahoma, Arial, sans-serif;font-weight;normal;      font-size: 10.5px !important;max-width:100%; letter-spacing: 0.1px;border:0}    h4{padding: 5px; display: inline-block; font-size: 14px; font-weight: normal; width: 100%; margin: 0;}        .very-first-block {position: relative; height:auto;border-right:1px solid black; min-height: 1px; float: left;padding-right: 2px;padding-left: 2px;      width: 50%;}    .first-block-name{margin-right: 20px}     .first-block-sold-to {      position: relative;      min-height: 82px;      height: auto;      float: left;      padding-bottom:5px;      padding-right: 2px;      border-right: 1px solid black;      background: #fff;      width: 100%;      margin-top:-2px         }        .first-block-ship-to {      position: relative;      min-height: 80px;      padding-bottom:5px;      height: auto;      padding-right: 2px;      border-right: 1px solid black;      background: #fff;      width: 100%;        }        .first-block-sold {      position: relative;      min-height: 120px;      height:auto;      float: left;      border-right:1px solid black;      padding-right: 2px;      padding-left: 2px;      margin-left:-1px;      width: 50%;    }        .first-block-ship {      position: relative;      min-height: 1px;      float: right;      padding-right: 2px;           width: 49%;    }        .address-block {      position: relative;      min-height: 1px;      float: left;      height:auto;      padding-right: 2px;      // border: 1px solid black;      width: 100%;      padding-left: 2px;    }        .first-block-address {      margin-right: 20px;      text-align: left    }            .second-block {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      width: 42%;      height:auto;      padding-left: 2px;      box-sizing: border-box;    }        .second-block-div {      margin: 2px 0;      position: relative;      //display: flex;      min-height: 1px;      height:auto           width: 100%;    }    .label{      font-weight:500;    }        .second-block-label {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      padding-left: 2px;      font-family: Tahoma, Arial, sans-serif;          font-size: 10.5px !important;                width: 38.33333333%;          text-transform: capitalize;          margin-bottom: 0;          text-align: left;    }        .clear {      clear: both;    }        .form-div {      // top: 6px;      position: relative;      font-weight: normal;      font-size:12.5;      font-family: Tahoma, Arial, sans-serif;      // margin-top: 10px;         }    span {      font-weight: normal;      font-size: 10.5px !important;  }        .image {      border: 1px solid #000;      // padding: 5px;      width: 100%;      display: block;    }        .logo-block {      margin: auto;      text-align: center    }        .pdf-block {      width: 800px;      margin: auto;      font-family: Tahoma, Arial, sans-serif;      font-weight:normal;      border: 1px solid #ccc;      padding: 25px 15px;    }        .picked-by {      position: relative;      float: left;      width: 48%;      font-family: Tahoma, Arial, sans-serif;      font-size: 10.5px !important;      font-weight: 700;    }        .confirmed-by {      position: relative;      float: right;      width: 48%;      font-family: Tahoma, Arial, sans-serif;      font-size: 10.5px !important;      font-weight: 700;    }        .first-part {      position: relative;      display: inline;      float: left;      width: 50%    }        .seond-part {      position: relative;      display: flex;      float: right;      width: 24%    }        .input-field-border {      width: 88px;      border-radius: 0px !important;      border: none;      border-bottom: 1px solid black;    }        .border-transparent {      border-block-color: white;    }        .pick-ticket-header {      border: 1px solid black;      text-align: center;      background: #0d57b0 !important;      color: #fff !important;      -webkit-print-color-adjust: exact;    }        .first-block-label {      position: relative;      min-height: 1px;      float: left;      padding-right: 2px;      padding-left: 2px;      // width: 38.33333333%;      font-size:10.5px !important;          font-family: Tahoma, Arial, sans-serif;             text-transform: capitalize;      margin-bottom: 0;      text-align: left;    }        .very-first-block {      position: relative;      min-height: 129px;      float: left;      height:auto;     border-right:1px solid black;      padding-right: 2px;      padding-left: 2px;      width: 57% !important;    }        .logo {      padding-top: 10px;          // height:70px;          // width:220px;          height:auto;          max-width:100%;          padding-bottom:10px;    }        .sold-block-div {      //margin: 1px 0;      position: relative;      display: inline-block;      min-height: 1px;      width: 100%;    }        .ship-block-div {      //margin: 1px 0;      position: relative;      display: inline-block;      min-height: 1px;      width: 100%;    }    .first-block-sold-bottom{      border-bottom: 1px solid black;          position:relative;          min-height:1px;          height:auto;          width:100%;          float:left;            // margin-top: -2px;           // min-height: 120px;    }        .parttable th {      background: #c7c6c6 !important; text-align: left;      color: #000 !important;      -webkit-print-color-adjust: exact;    }    .border-bottom{      border-bottom:1px solid black !important;    }    .table-margins{          margin-top:-1px;margin-left:0px        }    .invoice-border{      border-bottom: 1px solid;          position:relative;            // min-height: 119px;            min-height:1px;            height: auto;            width:100%;          float:left;}                                                  .capitalletter{text-transform: uppercase !important;}         
        </style>
      </head>
      <body>
        <!--<h4 style="border-bottom:0px solid">Speed Quote Exclusion</h4>-->
        <form id="" name="" action="#" method="post" onsubmit="return false;">
          <div class="image">
            <div style="padding: 0; margin: 0; border-right: none;">
              <form id="" class="form-div" name="" action="#" method="post" onsubmit="return false;">
                <!-- <div class="logo-block"><img src="http://design.poweraerosuites.com/image/logo.png" width="130" /></div><div class="clear"></div><hr /> -->
                <div class="col-sm-12 invoice-border">
                  <div class="very-first-block col-sm-8">
                    <div class="col-sm-12 address-block" style="width:100%;">
                      <div class="col-sm-6" style="width:48%; float: left;">
                        <img class="logo" src="##ManagementLogo##" />
                      </div>
                      <div class="col-sm-6" style="width:50%; padding-top:5px; margin-left:20px; float: right;">
                        <div class="col-sm-12 first-block-name">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##CompanyName##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##Address1##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##City##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##StateOrProvince##, ##PostalCode##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##Country##</label>
                        </div>
                        <div class="col-sm-12 sold-block-div">
                          <label class="col-sm-12 first-block-label capitalletter" disabled>##PhoneNo##</label>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="second-block col-sm-4">
                    <h3 style="margin-top: 1px; margin-bottom: -2px; margin-left: -2px; border-bottom: 1px solid black !important; text-align: center; width: 102%;"> Receiving Stock PO</h3>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''r Num</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>-</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''d Date:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>-</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">PO/RO Num:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##PurchaseOrderNumber##</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Date:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##OpenDate##</label>
                    </div>
                    <div class="second-block-div">
                      <label class="col-sm-6 second-block-label" style="width:48%">Rec''d By:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##PreparedBy##</label>
                    </div>
                    <div class="second-block-div" style="margin-top:30px">
                      <label class="col-sm-6 second-block-label" style="width:48%">Print Date/Time:</label>
                      <label class="col-sm-6 second-block-label" style="width:48%" disabled>##Printdate##</label>
                    </div>
                  </div>
                </div>
                <div class="col-sm-12"></div>
                <div class="clear"></div>
                <div class="col-sm-12"> ##exclusionparts## </div>
                <!--<div style="height:100px"> &nbsp;</div>-->
              </form>
            </div>
          </div>
        </form>
      </body>
    </div>
</html>',2,'AUTO SCRIPT','AUTO SCRIPT',GETDATE(),GETDATE(),1,0,'',(SELECT TOP 1 EmailTemplateTypeId FROM EmailTemplateType where EmailTemplateType='Receiver Stock PDF'),'',1,GETDATE());