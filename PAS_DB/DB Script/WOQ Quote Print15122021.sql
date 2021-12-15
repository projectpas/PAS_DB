UPDATE EmailTemplate SET TemplateDescription='<html>
  <head>
    <style>
      table {
        width: 100.6%;
        overflow: auto !important;
      }

      table thead {
        background: #808080;
      }

      table thead tr {
        /* background: #0d57b0 !important; */
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

      .table-border-right tr td {
        border-right: 1px solid black !important;
      }

      .table-border-top {
        border-top: 1px solid black !important;
      }

      table thead tr th {
        /* background: #0d57b0 !important; */
        padding: 5px !important;
        color: #000;
        letter-spacing: 0.3px;
        font-size: 10.5px;
        text-transform: capitalize;
        z-index: 1;
      }

      table tbody {
        overflow-y: auto;
        max-height: 500px;
      }

      table tbody tr td {
        background: #fff;
        padding: 2px;
        line-height: 22px;
        height: 22px;
        color: #333; // border-right: 1px solid black !important;                 font-family: Tahoma, Arial, sans-serif;                 font-size: 10.5px !important;   //font-weight: 700;   max-width: 100px;                 letter-spacing: 0.1px;                 border: 0             }          .td-width-25 {             width: 25%;         }          h4 {             padding: 5px;             display: inline-block;             font-size: 14px;             font-weight: 600;             width: 100%;             margin: 0;         }          hr {             margin-top: 10px;             margin-bottom: 10px;             border: 0;             border-top: 1px solid #e0e0e0;             height: 0;             box-sizing: content-box;         }          .first-block-name {             margin-right: 20px         }          .first-block-sold-to {             position: relative;             min-height: 142px;             height: auto;             float: left;             padding-right: 2px;             /* border-right: 1px solid black; */             background: #fff;             width: 100%;         }          .first-block-ship-to {             position: relative;             min-height: 140px;             height: auto;             padding-right: 2px;             /* border-right: 1px solid black; */             background: #fff;             width: 100%;         }          .text-right {             text-align: right;         }          .border-none {             border: none;         }          .label-margin {             margin-left: -25px;         }          .first-block-sold {             position: relative;             min-height: 140px;             height: auto;             float: left;             border-right: 1px solid black;             padding-right: 2px;             padding-left: 2px;             width: 50%;         }          .first-block-ship {             position: relative;             min-height: 1px;             float: right;             padding-right: 2px;             padding-left: 2px;             width: 50%;         }          .font-12 {             font-size: 12px;         }          .address-block {             position: relative;             min-height: 1px;             float: left;             padding-right: 2px;             /* border: 1px solid black; */             width: 100%;             padding-left: 2px;         }          .first-block-address {             margin-right: 20px;             text-align: left         }          .second-block {             position: relative;             height: auto;             min-height: 161px;             margin-top: -2px;             float: left;             padding-right: 2px;             // width: 35%;             width: 29%;             /* border-left:1px solid black;      margin-left: 16%; */             padding-left: 2px;             box-sizing: border-box;         }          .second-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .second-block-label {             position: relative;             min-height: 1px;             float: left;             padding-right: 2px;             padding-left: 2px;             width: 38.33333333%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;             text-transform: capitalize;             margin-bottom: 0;             text-align: left;         }          .clear {             clear: both;         }          .form-div {             /* top: 6px; */             position: relative;             font-weight: normal;             font-family: Tahoma, Arial, sans-serif;             /* margin-top: 10px; */         }          .image {             border: 1px solid #000;             /* padding: 5px; */             width: 100%;             display: block;         }          .logo-block {             margin: auto;             text-align: center         }          .pdf-block {             width: 800px;             margin: auto;             border: 1px solid #ccc;             padding: 25px 15px;         }          .picked-by {             position: relative;             float: left;             width: 48%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;         }          .confirmed-by {             position: relative;             float: right;             width: 48%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;         }          .first-part {             position: relative;             display: inline;             float: left;             width: 50%         }          .seond-part {             position: relative;             display: flex;             float: right;             width: 24%         }          .input-field-border {             width: 88px;             border-radius: 0px !important;             border: none;             border-bottom: 1px solid black;         }          .border-transparent {             border-block-color: white;         }          .pick-ticket-header {             border: 1px solid black;             text-align: center;             background: #0d57b0 !important;             color: #fff !important;             -webkit-print-color-adjust: exact;         }          .first-block-label {             position: relative;             min-height: 1px;             float: left;             width: 100%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;             padding-right: 2px;             padding-left: 2px;             /* width: 38.33333333%; */             text-transform: capitalize;             margin-bottom: 0;             text-align: left;         }          .border-top {             border-top: 1px solid black !important;         }          .align-top {             vertical-align: top;         }          .top-table-alignment {             margin-bottom: -3px;             width: 102%;             margin-left: -7px !important;         }          .border {             border: 1px solid black !important;         }          .very-first-block {             position: relative;             min-height: 200px;             height: auto;             border-right: 1px solid black;             float: left;             // padding-right: 2px;             // padding-left: 2px;             width: 70% !important;         }          .logo {             padding-top: 10px;             /* height:110px;    width:300px; */             height: auto;             max-width: 100%;         }          .sold-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .ship-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .first-block-sold-bottom {             border-bottom: 1px solid black;             margin-top: -2px;             height: auto;             min-height: 140px;         }            .parttable th {               /*background: #fff !important;*/              background: #f4f4f4 !important;              color: #000 !important;              -webkit-print-color-adjust: exact;              font-family: Tahoma, Arial, sans-serif;          }          .border-bottom {             border-bottom: 1px solid black !important;         }          .table-margins {             /* margin-top:20px; */             margin-top: -5px;             margin-left: -3px;         }          .invoice-border {             border-bottom: 1px solid;             min-height: 200px;             height: auto;         }      .headerfirst td{     font-size: 14.5px !important;     padding-bottom: 10px !important;      }     .tablefirstrow{   font-weight: normal;     }     .totalrow{   font-weight: bold !important;   font-family: Tahoma, Arial, sans-serif;     }           
    </style>
  </head>
  <body>
    <form id="" name="" action="#" method="post" onsubmit="return false;">
      <div class="image">
        <div style="padding: 0; margin: 0;">
          <div>
            <form id="" name="" action=" #" method="post" onsubmit="return false;">
              <div style="margin-top: 4px;">
                <div>
                  <table class="print-friendly parttable print-table table-margins headerfirst">
                    <tr>
                      <td>
                        <b>Material List</b>
                      </td>
                      <td></td>
                      <td>
                        <b>Work Order Quote: ##quoteNumber##</b>
                      </td>
                      <td></td>
                    </tr>
                  </table>
                </div>
                <div>
                  <table class="print-friendly parttable print-table table-margins">
                    <tr>
                      <td>
                        <b>Cust Name & Cust Code:</b> ##CustomerName##
                      </td>
                      <td></td>
                      <!--<td>QuoteNumber: ##quoteNumber##</td>-->
                      <td></td>
                      <td></td>
                    </tr>
                    <tr>
                      <td>
                        <b>Work Order Num:</b> ##workOrderNum##
                      </td>
                      <td></td>
                      <td></td>
                      <td></td>
                    </tr>
                  </table>
                </div>
                <table rules="none" class="print-friendly border table-border-right parttable print-table table-margins">
                  <thead>
                    <tr>
                      <th style="min-width: 120px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;">MPN : <label class="tablefirstrow">##partnumber##</label>
                      </th>
                      <th style="min-width: 130px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;" colspan="2">MPN Description : <label class="tablefirstrow">##partDescription##</label>
                      </th>
                      <th style="min-width: 120px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;" colspan="2">Quote Method : <label class="tablefirstrow">##quoteMethod##</label>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                </table>
                <table class="print-friendly border table-border-right parttable print-table table-margins">
                  <thead>
                    <tr>
                      <th class="font-12" style="min-width: 100px; display: ##showpn##">Parts/Material List PN</th>
                      <th class="font-12" style="min-width: 220px; display: ##showpnDescription##">PN Description</th>
                      <th class="font-12" style="min-width: 20px; display: ##showuom##">UOM</th>
                      <th class="font-12" style="min-width: 40px; display: ##showqty##">Qty</th>
                      <th class="font-12" style="min-width: 20px; display: ##showUnitprice##">Unit Price</th>
                      <th class="font-12" style="min-width: 20px; display: ##showExtPrice##">Ext price</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr> ##PARTREPEATER## </tr>
                    <!-- <tr> -->
                    <!-- ##PARTREPEATER## -->
                    <!-- </tr> -->
                    <tr style="border:1px solid black">
                      <td colspan="5">
                        <b>Total Material </b>
                      </td>
                      <td class="text-right">
                        <b>##materialFlatBillingAmount##</b>
                      </td>
                    </tr>
                    <!--<tr style="border:1px solid black"><td colspan="5"><b>Labor Cost </b></td><td class="text-right">##laborFlatBillingAmount##</td></tr><tr style="border:1px solid black"><td colspan="5"><b>Misc Charges </b></td><td class="text-right">##chargesFlatBillingAmount##</td></tr><tr style="border:1px solid black"><td colspan="5"><b>FREIGHT Cost </b></td><td class="text-right">##freightFlatBillingAmount##</td></tr><tr style="border:0px solid black"><td colspan="5"><b>Total Amount PN </b></td><td class="text-right"><b>##totalAmountPN##</b></td></tr>-->
                  </tbody>
                </table>
              </div>
            </form>
          </div>
        </div>
      </div>
    </form>
    </div>
    </div>
    </form>
  </body>
</html>',EmailBody='<html>
  <head>
    <style>
      table {
        width: 100.6%;
        overflow: auto !important;
      }

      table thead {
        background: #808080;
      }

      table thead tr {
        /* background: #0d57b0 !important; */
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

      .table-border-right tr td {
        border-right: 1px solid black !important;
      }

      .table-border-top {
        border-top: 1px solid black !important;
      }

      table thead tr th {
        /* background: #0d57b0 !important; */
        padding: 5px !important;
        color: #000;
        letter-spacing: 0.3px;
        font-size: 10.5px;
        text-transform: capitalize;
        z-index: 1;
      }

      table tbody {
        overflow-y: auto;
        max-height: 500px;
      }

      table tbody tr td {
        background: #fff;
        padding: 2px;
        line-height: 22px;
        height: 22px;
        color: #333; // border-right: 1px solid black !important;                 font-family: Tahoma, Arial, sans-serif;                 font-size: 10.5px !important;   //font-weight: 700;   max-width: 100px;                 letter-spacing: 0.1px;                 border: 0             }          .td-width-25 {             width: 25%;         }          h4 {             padding: 5px;             display: inline-block;             font-size: 14px;             font-weight: 600;             width: 100%;             margin: 0;         }          hr {             margin-top: 10px;             margin-bottom: 10px;             border: 0;             border-top: 1px solid #e0e0e0;             height: 0;             box-sizing: content-box;         }          .first-block-name {             margin-right: 20px         }          .first-block-sold-to {             position: relative;             min-height: 142px;             height: auto;             float: left;             padding-right: 2px;             /* border-right: 1px solid black; */             background: #fff;             width: 100%;         }          .first-block-ship-to {             position: relative;             min-height: 140px;             height: auto;             padding-right: 2px;             /* border-right: 1px solid black; */             background: #fff;             width: 100%;         }          .text-right {             text-align: right;         }          .border-none {             border: none;         }          .label-margin {             margin-left: -25px;         }          .first-block-sold {             position: relative;             min-height: 140px;             height: auto;             float: left;             border-right: 1px solid black;             padding-right: 2px;             padding-left: 2px;             width: 50%;         }          .first-block-ship {             position: relative;             min-height: 1px;             float: right;             padding-right: 2px;             padding-left: 2px;             width: 50%;         }          .font-12 {             font-size: 12px;         }          .address-block {             position: relative;             min-height: 1px;             float: left;             padding-right: 2px;             /* border: 1px solid black; */             width: 100%;             padding-left: 2px;         }          .first-block-address {             margin-right: 20px;             text-align: left         }          .second-block {             position: relative;             height: auto;             min-height: 161px;             margin-top: -2px;             float: left;             padding-right: 2px;             // width: 35%;             width: 29%;             /* border-left:1px solid black;      margin-left: 16%; */             padding-left: 2px;             box-sizing: border-box;         }          .second-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .second-block-label {             position: relative;             min-height: 1px;             float: left;             padding-right: 2px;             padding-left: 2px;             width: 38.33333333%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;             text-transform: capitalize;             margin-bottom: 0;             text-align: left;         }          .clear {             clear: both;         }          .form-div {             /* top: 6px; */             position: relative;             font-weight: normal;             font-family: Tahoma, Arial, sans-serif;             /* margin-top: 10px; */         }          .image {             border: 1px solid #000;             /* padding: 5px; */             width: 100%;             display: block;         }          .logo-block {             margin: auto;             text-align: center         }          .pdf-block {             width: 800px;             margin: auto;             border: 1px solid #ccc;             padding: 25px 15px;         }          .picked-by {             position: relative;             float: left;             width: 48%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;         }          .confirmed-by {             position: relative;             float: right;             width: 48%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;         }          .first-part {             position: relative;             display: inline;             float: left;             width: 50%         }          .seond-part {             position: relative;             display: flex;             float: right;             width: 24%         }          .input-field-border {             width: 88px;             border-radius: 0px !important;             border: none;             border-bottom: 1px solid black;         }          .border-transparent {             border-block-color: white;         }          .pick-ticket-header {             border: 1px solid black;             text-align: center;             background: #0d57b0 !important;             color: #fff !important;             -webkit-print-color-adjust: exact;         }          .first-block-label {             position: relative;             min-height: 1px;             float: left;             width: 100%;             font-family: Tahoma, Arial, sans-serif;             font-size: 10.5px !important;             font-weight: 700;             padding-right: 2px;             padding-left: 2px;             /* width: 38.33333333%; */             text-transform: capitalize;             margin-bottom: 0;             text-align: left;         }          .border-top {             border-top: 1px solid black !important;         }          .align-top {             vertical-align: top;         }          .top-table-alignment {             margin-bottom: -3px;             width: 102%;             margin-left: -7px !important;         }          .border {             border: 1px solid black !important;         }          .very-first-block {             position: relative;             min-height: 200px;             height: auto;             border-right: 1px solid black;             float: left;             // padding-right: 2px;             // padding-left: 2px;             width: 70% !important;         }          .logo {             padding-top: 10px;             /* height:110px;    width:300px; */             height: auto;             max-width: 100%;         }          .sold-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .ship-block-div {             margin: 2px 0;             position: relative;             display: flex;             min-height: 1px;             width: 100%;         }          .first-block-sold-bottom {             border-bottom: 1px solid black;             margin-top: -2px;             height: auto;             min-height: 140px;         }            .parttable th {               /*background: #fff !important;*/              background: #f4f4f4 !important;              color: #000 !important;              -webkit-print-color-adjust: exact;              font-family: Tahoma, Arial, sans-serif;          }          .border-bottom {             border-bottom: 1px solid black !important;         }          .table-margins {             /* margin-top:20px; */             margin-top: -5px;             margin-left: -3px;         }          .invoice-border {             border-bottom: 1px solid;             min-height: 200px;             height: auto;         }      .headerfirst td{     font-size: 14.5px !important;     padding-bottom: 10px !important;      }     .tablefirstrow{   font-weight: normal;     }     .totalrow{   font-weight: bold !important;   font-family: Tahoma, Arial, sans-serif;     }           
    </style>
  </head>
  <body>
    <form id="" name="" action="#" method="post" onsubmit="return false;">
      <div class="image">
        <div style="padding: 0; margin: 0;">
          <div>
            <form id="" name="" action=" #" method="post" onsubmit="return false;">
              <div style="margin-top: 4px;">
                <div>
                  <table class="print-friendly parttable print-table table-margins headerfirst">
                    <tr>
                      <td>
                        <b>Material List</b>
                      </td>
                      <td></td>
                      <td>
                        <b>Work Order Quote: ##quoteNumber##</b>
                      </td>
                      <td></td>
                    </tr>
                  </table>
                </div>
                <div>
                  <table class="print-friendly parttable print-table table-margins">
                    <tr>
                      <td>
                        <b>Cust Name & Cust Code:</b> ##CustomerName##
                      </td>
                      <td></td>
                      <!--<td>QuoteNumber: ##quoteNumber##</td>-->
                      <td></td>
                      <td></td>
                    </tr>
                    <tr>
                      <td>
                        <b>Work Order Num:</b> ##workOrderNum##
                      </td>
                      <td></td>
                      <td></td>
                      <td></td>
                    </tr>
                  </table>
                </div>
                <table rules="none" class="print-friendly border table-border-right parttable print-table table-margins">
                  <thead>
                    <tr>
                      <th style="min-width: 120px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;">MPN : <label class="tablefirstrow">##partnumber##</label>
                      </th>
                      <th style="min-width: 130px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;" colspan="2">MPN Description : <label class="tablefirstrow">##partDescription##</label>
                      </th>
                      <th style="min-width: 120px;text-align: left;padding: 5px !important; padding-bottom: 7px !important;" colspan="2">Quote Method : <label class="tablefirstrow">##quoteMethod##</label>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                </table>
                <table class="print-friendly border table-border-right parttable print-table table-margins">
                  <thead>
                    <tr>
                      <th class="font-12" style="min-width: 100px; display: ##showpn##">Parts/Material List PN</th>
                      <th class="font-12" style="min-width: 220px; display: ##showpnDescription##">PN Description</th>
                      <th class="font-12" style="min-width: 20px; display: ##showuom##">UOM</th>
                      <th class="font-12" style="min-width: 40px; display: ##showqty##">Qty</th>
                      <th class="font-12" style="min-width: 20px; display: ##showUnitprice##">Unit Price</th>
                      <th class="font-12" style="min-width: 20px; display: ##showExtPrice##">Ext price</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr> ##PARTREPEATER## </tr>
                    <!-- <tr> -->
                    <!-- ##PARTREPEATER## -->
                    <!-- </tr> -->
                    <tr style="border:1px solid black">
                      <td colspan="5">
                        <b>Total Material </b>
                      </td>
                      <td class="text-right">
                        <b>##materialFlatBillingAmount##</b>
                      </td>
                    </tr>
                    <!--<tr style="border:1px solid black"><td colspan="5"><b>Labor Cost </b></td><td class="text-right">##laborFlatBillingAmount##</td></tr><tr style="border:1px solid black"><td colspan="5"><b>Misc Charges </b></td><td class="text-right">##chargesFlatBillingAmount##</td></tr><tr style="border:1px solid black"><td colspan="5"><b>FREIGHT Cost </b></td><td class="text-right">##freightFlatBillingAmount##</td></tr><tr style="border:0px solid black"><td colspan="5"><b>Total Amount PN </b></td><td class="text-right"><b>##totalAmountPN##</b></td></tr>-->
                  </tbody>
                </table>
              </div>
            </form>
          </div>
        </div>
      </div>
    </form>
    </div>
    </div>
    </form>
  </body>
</html>' where TemplateName='WOQ Quote Print';