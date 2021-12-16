



INSERT INTO [dbo].[EmailTemplateType]
           ([EmailTemplateType]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted])
     VALUES
           ('ReceivingInspection'
           ,0
           ,'admin'
           ,'admin'
           , GETDATE()
           ,GETDATE()
           ,1
           ,0);
		   

INSERT INTO [dbo].[EmailTemplate]
           ([TemplateName]
           ,[TemplateDescription]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[EmailBody]
           ,[EmailTemplateTypeId]
           ,[SubjectName]
           ,[RevNo]
           ,[RevDate])
     VALUES
           ('ReceivingInspection','',1,'admin','admin',GETDATE(),GETDATE(),1,0,'',62,'ReceivingInspection',1,GETDATE()),
		   ('ReceivingInspection','',2,'admin','admin',GETDATE(),GETDATE(),1,0,'',62,'ReceivingInspection',1,GETDATE()),
		   ('ReceivingInspection','',3,'admin','admin',GETDATE(),GETDATE(),1,0,'',62,'ReceivingInspection',1,GETDATE()),
		   ('ReceivingInspection','',4,'admin','admin',GETDATE(),GETDATE(),1,0,'',62,'ReceivingInspection',1,GETDATE()),
		   ('ReceivingInspection','',5,'admin','admin',GETDATE(),GETDATE(),1,0,'',62,'ReceivingInspection',1,GETDATE());
		      




UPDATE EmailTemplate SET TemplateDescription = 

'<html>
<head>
	<style>
	.minus-button {
		background: darkgray;
		color: #fff;
	}
	
	input {
		width: 100%;
		padding: 7px;
		border-radius: 0px !important;
	}
	
	.row::after {
		content: "";
		clear: both;
		display: table;
	}
	
	.card-alignment {
		background: #fff;
		margin-top: 2%
	}
	
	select {
		padding: 7px;
		-webkit-appearance: menulist-button;
	}
	
	.create-button {
		padding: 4px 12px;
		margin-top: 10px;
		/* margin-right: 60px; */
		width: 100px;
		font-weight: 500;
		float: right;
		color: #fff;
		background-color: #2f0374;
		border: #2f0374;
		margin-bottom: 30px;
	}
	
	.question-div {
		word-wrap: break-word;
		display: inline-block;
		padding: .375rem .75rem !important;
		border: 1px solid #ced4da;
	}
	
	.export-button {
		padding: 4px 12px;
		width: 100px;
		margin-top: 20px;
		margin-right: 40px;
		font-weight: 500;
		float: right;
		color: #fff;
		background-color: #0198d5;
		border: #0198d5;
		margin-bottom: 20px;
	}
	
	.assign-unassign-button {
		padding: 3px 9px;
		margin-top: 0px;
		/* margin-right: 20px; */
		font-weight: 400;
		width: 120px;
		float: right;
		color: #61c4e3;
		background-color: #fff;
		border: 2px solid #61c4e3;
		margin-bottom: 14px;
	}
	
	.m-t-30 {
		margin-top: 30px;
	}
	
	.switch {
		position: relative;
		display: inline-block;
		width: 44px;
		float: right;
		margin-top: 5px;
		height: 14px;
	}
	
	.radio-label {
		margin-left: 3% !important;
		width: 46% !important;
	}
	
	.switch input {
		opacity: 0;
		width: 0;
		width: 3vmin;
		height: 3vmin;
		top: 0.5vmin;
		height: 0;
	}
	
	.checkbox-label {
		width: 90% !important;
		margin-left: 5% !important;
	}
	
	.table {
		width: 100%;
		margin-bottom: 1rem;
		background-color: #fff;
	}
	
	table thead th {
		background: #2f0374;
		color: #fff;
		font-weight: 400
	}
	
	.table thead th {
		vertical-align: middle;
		font-size: 14px;
		border-bottom: 2px solid #dee2e6;
	}
	
	.slider {
		position: absolute;
		cursor: pointer;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background-color: #ccc;
		-webkit-transition: .4s;
		transition: .4s;
	}
	
	.form-check {
		/* margin-top:10px */
	}
	
	.form-check-input {
		width: 20px;
		height: 20px
	}
	
	.form-check-label {
		margin-left: 3%;
		/* border: 1px solid #ced4da; */
		padding: .205rem .35rem;
		width: 41%;
	}
	
	.slider:before {
		position: absolute;
		content: "";
		height: 11px;
		width: 11px;
		left: -14px;
		bottom: 1.8px;
		background-color: white;
		-webkit-transition: .4s;
		transition: .4s;
		transform: translate3d(5vmin, 0, 0);
	}
	
	input:checked + .slider {
		background-color: #2196F3;
	}
	
	.toggle .track {
		width: 51px;
		height: 31px;
	}
	
	.toggle .handle {
		width: 20px;
		height: 20px;
		border-radius: 20px;
		top: 7px;
		left: 7px;
	}
	
	.m-l-10 {
		margin-left: 10px
	}
	
	.m-r-10 {
		margin-right: 10px;
	}
	
	input:focus + .slider {
		box-shadow: 0 0 1px #2196F3;
	}
	
	input:checked + .slider:before {
		-webkit-transform: translateX(26px);
		-ms-transform: translateX(26px);
		transform: translateX(26px);
	}
	
	.left-side-menu {
		background-color: #fff;
		border: 2px solid #e2e2e2;
		margin-right: 20px;
	}
	
	.checkbox-group-border {
		border: 1px solid #e8e9e9;
	}
	
	.checkbox-group {
		height: 154px;
		overflow: auto;
	}
	
	.roles-check-back {
		background: #f1f1f2;
	}
	/* Rounded sliders */
	
	.slider.round {
		border-radius: 34px;
		width: 26px;
		margin-left: 10px;
	}
	
	.arrow {
		border: solid #b3b3b3;
		border-width: 0 3px 3px 0;
		display: inline-block;
		padding: 4px;
	}
	
	.arrow-height {
		height: 20px;
	}
	
	.top-arrow {
		margin-top: 30px;
		height: 5px
	}
	
	.right {
		transform: rotate(-45deg);
		-webkit-transform: rotate(-45deg);
	}
	
	.left {
		transform: rotate(135deg);
		-webkit-transform: rotate(135deg);
	}
	
	.up {
		transform: rotate(-135deg);
		-webkit-transform: rotate(-135deg);
	}
	
	.down {
		transform: rotate(45deg);
		-webkit-transform: rotate(45deg);
	}
	
	.m-t-30 {
		margin-top: 30px
	}
	
	.slider.round:before {
		border-radius: 50%;
	}
	
	@media (min-width: 768px) {
		.col-md-3 {
			max-width: 22%;
		}
		.col-md-4 {
			max-width: 33%;
		}
		.col-md-6 {
			max-width: 44%;
		}
	}
	
	.col,
	.col-1,
	.col-10,
	.col-11,
	.col-12,
	.col-2,
	.col-3,
	.col-4,
	.col-5,
	.col-6,
	.col-7,
	.col-8,
	.col-9,
	.col-auto,
	.col-lg,
	.col-lg-1,
	.col-lg-10,
	.col-lg-11,
	.col-lg-12,
	.col-lg-2,
	.col-lg-3,
	.col-lg-4,
	.col-lg-5,
	.col-lg-6,
	.col-lg-7,
	.col-lg-8,
	.col-lg-9,
	.col-lg-auto,
	.col-md,
	.col-md-1,
	.col-md-10,
	.col-md-11,
	.col-md-12,
	.col-md-2,
	.col-md-3,
	.col-md-4,
	.col-md-5,
	.col-md-6,
	.col-md-7,
	.col-md-8,
	.col-md-9,
	.col-md-auto,
	.col-sm,
	.col-sm-1,
	.col-sm-10,
	.col-sm-11,
	.col-sm-12,
	.col-sm-2,
	.col-sm-3,
	.col-sm-4,
	.col-sm-5,
	.col-sm-6,
	.col-sm-7,
	.col-sm-8,
	.col-sm-9,
	.col-sm-auto,
	.col-xl,
	.col-xl-1,
	.col-xl-10,
	.col-xl-11,
	.col-xl-12,
	.col-xl-2,
	.col-xl-3,
	.col-xl-4,
	.col-xl-5,
	.col-xl-6,
	.col-xl-7,
	.col-xl-8,
	.col-xl-9,
	.col-xl-auto {
		position: relative;
		width: 100%;
		padding-right: 0px;
		padding-left: 0px;
	}
	
	@media only screen and (min-width: 600px) {
		/* For tablets: */
		.col-s-1 {
			width: 8.33%;
		}
		.col-s-2 {
			width: 16.66%;
		}
		.col-s-3 {
			width: 25%;
		}
		.col-s-4 {
			width: 33.33%;
		}
		.col-s-5 {
			width: 41.66%;
		}
		.col-s-6 {
			width: 50%;
		}
		.col-s-7 {
			width: 58.33%;
		}
		.col-s-8 {
			width: 66.66%;
		}
		.col-s-9 {
			width: 75%;
		}
		.col-s-10 {
			width: 83.33%;
		}
		.col-s-11 {
			width: 91.66%;
		}
		.col-s-12 {
			width: 100%;
		}
	}
	
	@media only screen and (min-width: 768px) {
		/* For desktop: */
		.col-md-1 {
			width: 8.33%;
		}
		.col-md-2 {
			width: 16.66%;
		}
		.col-md-3 {
			width: 25%;
		}
		.col-md-4 {
			width: 33.33%;
		}
		.col-md-5 {
			width: 41.66%;
		}
		.col-md-6 {
			width: 50%;
		}
		.col-md-7 {
			width: 58.33%;
		}
		.col-md-8 {
			width: 66.66%;
		}
		.col-md-9 {
			width: 75%;
		}
		.col-md-10 {
			width: 83.33%;
		}
		.col-md-11 {
			width: 91.66%;
		}
		.col-md-12 {
			width: 100%;
		}
	}
	
	.form-group {
		width: 90%;
		margin-bottom: 10px;
		margin-right: 10px;
	}
	
	.display-flex {
		display: flex;
	}
	
	.div-border {
		border: 1px solid #000
	}
	
	.m-t-20 {
		margin-top: 20px
	}
	
	.card-body {
		padding: 20px;
		border: 2px solid #e2e2e2;
	}
	
	.number-span {
		margin-left: 3%;
		margin-right: 3%
	}
	
	.header {
		padding: 1.25rem 0.25rem 1.15rem 1.25rem;
		background-color: #380c9f;
	}
	
	.header-name {
		color: #fff;
		font-size: 22px;
		/* font-weight: bold; */
		/* font-family: openSans; */
		padding-left: 16px;
		margin: 0px !important;
	}
	
	.clr-red {
		color: #ff5663;
	}
	
	.label-font-weight {
		font-weight: 500;
		font-size: 14px;
	}
	
	.edit-a {
		color: #56ace6;
		font-weight: 500
	}
	
	.delete-a {
		color: #e74f33;
		font-weight: 500
	}
	
	.edit-a:hover {
		color: #56ace6;
	}
	
	.delete-a:hover {
		color: #e74f33
	}
	
	td span a {
		text-decoration: underline;
	}
	
	ul,
	li {
		list-style: none;
		margin-top: 16px;
	}
	
	.breadcrumb {
		display: flex;
		float: right;
		font-size: 16px;
		font-weight: 400;
		background: none;
		border-radius: none;
		margin-bottom: 0px;
		padding: 0px;
	}
	
	.header {
		background: #f1f1f1;
		padding: 8px 12px !important;
		color: #6e6e6e;
		font-weight: 700;
		font-size: 32px;
	}
	
	a {
		color: #6e6e6e;
	}
	
	.m-t-20 {
		margin-top: 20px;
	}
	
	.m-b-20 {
		margin-bottom: 20px
	}
	
	input {
		border: 2px solid #979ba5;
	}
	</style>
</head>

<body>
	<form id="" name="" action=" #" method="post" onsubmit="return false;">
		
		<div class="col-md-12 form-group div-border" style="text-align:center;font-size: 14px;width:780px;">RECEIVING INSPECTION FORM</div>

		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:40px;width:380px;">
					<label style="font-size: 12px;"> Company ##CompanyName##</label>
				</div>
			</div>			
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:40px;width:380px;">
					<label style="font-size: 12px;"> Cert Num: ##PartCertificationNumber##</label>
				</div>
			</div>
		</div>
		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -102px;margin-left: 400px;">
					<label style="font-size: 12px;"> Address1 ##Address1##</label>
				</div>
			</div>
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -30px;margin-left: 400px;">
					<label style="font-size: 12px;"> Address2 ##Address2##</label>
				</div>
			</div>
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -30px;margin-left: 400px;">
					<label style="font-size: 12px;"> City ##City##</label>
				</div>
			</div>
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -30px;margin-left: 400px;">
					<label style="font-size: 12px;"> State/Prov ##StateOrProvince##</label>
				</div>
			</div>
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -30px;margin-left: 400px;">
					<label style="font-size: 12px;"> Zip ##PostalCode##</label>
				</div>
			</div>
			<div class="col-md-6">
				<div class="col-md-12 form-group" style="height:50px;width:380px;margin-top: -30px;margin-left: 400px;">
					<label style="font-size: 12px;"> Country ##Country##</label>
				</div>
			</div>
		</div>
		 <hr>		
		<div class="col-md-12 form-group" style="text-align:center;font-size: 14px;width:780px;">Please populate all items</div>
		<div class="form-row">
             <div class="col-md-12">
                 <div class="form-row">
                     <div class="col-md-6">
                         <div class="form-group" style="padding-top:8px">                                    
                             <label style="font-size: 12px;"> PO/RO Num : ##PORONum##</label>
                         </div>
                     </div>                           
                 </div>                                              
              </div>
        </div>
		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-6">
				<div>
					<label style="font-size: 16px;"><u>Yes</u>&nbsp;&nbsp;&nbsp;<u>No</u>&nbsp;&nbsp;&nbsp;<u>NA</u></label>
				</div>
				<div style="margin-left: 340px;margin-top: -22px">
					<label style="font-size: 16px;"><u>Yes</u>&nbsp;&nbsp;&nbsp;<u>No</u>&nbsp;&nbsp;&nbsp;<u>NA</u></label>
				</div>
			</div>
		</div>
		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-6">
				<div class="form-check">					
					<div style="margin-top: -5px">
						<input class="form-check-input" type="checkbox" value="" id="istheIDPlatemissing" ##1Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="istheIDPlatemissing" ##1No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="istheIDPlatemissing" ##1NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="istheIDPlatemissing">PN</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="SerialNum" ##2Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="SerialNum" ##2No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="SerialNum" ##2NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="SerialNum">Serial Num</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="COND" ##3Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="COND" ##3No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="COND" ##3NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="COND">Cond</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="Qty" ##4Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="Qty" ##4No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="Qty" ##4NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="Qty">Qty</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="ShelfLife" ##5Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="ShelfLife" ##5No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="ShelfLife" ##5NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="ShelfLife">Shelf Life</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="LotBatchNum" ##6Yes##> 
					</div>
					<div style="margin-top: -26px;margin-left: 35px">
						<input class="form-check-input" type="checkbox" value="" id="LotBatchNum" ##6No##> 
					</div>
					<div style="margin-top: -26px;margin-left: 70px">
						<input class="form-check-input" type="checkbox" value="" id="LotBatchNum" ##6NA##> 
					</div>
					<div style="margin-top: -22px;margin-left: 100px">
						<label style="font-size: 14px;" for="LotBatchNum">Lot/Batch Num</label>
					</div>
				</div>						
			</div>
			<div class="col-md-6">
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: -135px">
						<input class="form-check-input" type="checkbox" value="" id="GeneralVisualInspection" ##7Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="GeneralVisualInspection" ##7No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="GeneralVisualInspection" ##7NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="GeneralVisualInspection">General Visual Inspection</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="AppropriatePackaging" ##8Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="AppropriatePackaging" ##8No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="AppropriatePackaging" ##8NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="GeneralVisualInspection">Appropriate Packaging</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="ESDCapsandPackaging" ##9Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="ESDCapsandPackaging" ##9No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="ESDCapsandPackaging" ##9NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="ESDCapsandPackaging">ESD Caps and Packaging</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="HazardousMaterial" ##10Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="HazardousMaterial" ##10No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="HazardousMaterial" ##10NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="HazardousMaterial">Hazardous Material</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="MeetsPORequirements" ##11Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="MeetsPORequirements" ##11No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="MeetsPORequirements" ##11NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="MeetsPORequirements">Meets PO Requirements</label>
					</div>
				</div>
				<div class="form-check">					
					<div style="margin-left: 340px;margin-top: 1px">
						<input class="form-check-input" type="checkbox" value="" id="CompletePaperwork" ##12Yes##> 
					</div>
					<div style="margin-left: 375px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="CompletePaperwork" ##12No##> 
					</div>
					<div style="margin-left: 410px;margin-top: -26px">
						<input class="form-check-input" type="checkbox" value="" id="CompletePaperwork" ##12NA##> 
					</div>
					<div style="margin-left: 440px;width:380px;margin-top: -22px;">
						<label style="font-size: 14px;" for="CompletePaperwork">Complete Paperwork</label>
					</div>
				</div>
			</div>
		</div>
		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-12">
				<div class="col-md-12 form-group  div-border" style="min-height:120px;margin-top: 50px;width:780px;">
					<label style="font-size: 12px;">10. Note Discrepancies: ##Notes##</label>
				</div>
			</div>
		</div>
		<div class="col-md-12 form-group" style="text-align:center;font-size: 14px;width:780px;">All Orders with discrepancies will be quarantined</div>
		<div class="col-md-12 form-group" style="text-align:center;font-size: 14px;width:780px;">Notify purchasing dept of any discrepancy</div>
		<div class="form-row">
             <div class="col-md-12">
                 <div class="form-row">
                     <div class="col-md-6">
                         <div class="form-group" style="padding-top:8px">                                    
                             <label style="font-size: 12px;"> Signature : ##Signature##</label>
                         </div>
                     </div>       
					 <div class="col-md-6">
                         <div class="form-group" style="padding-top:8px">                                    
                             <label style="font-size: 12px;"> Date : ##ReceivedDate##</label>
                         </div>
                     </div> 
                 </div>                                              
              </div>
        </div>		
		<div class="col-md-12 form-group  display-flex">
			<div class="col-md-4">
				<div class="col-md-12 form-group" style="height:40px;width:280px;margin-top: 20px;">
					<label style="font-size: 12px;"> Form # </label>
				</div>
			</div>
			<div class="col-md-4">
				<div class="col-md-12 form-group" style="height:40px;width:180px;margin-top: -52px;margin-left: 300px;">
					<label style="font-size: 12px;"> Revised Date  </label>
				</div>
			</div>			
		</div>
	</form>
</body>
</html>'

WHERE TemplateName = 'ReceivingInspection';





