/*************************************************************           
 ** File:   [USP_CreateUpdateReleaseForm]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create And Update Work Order Release Form 8130
 ** Purpose:         
 ** Date:   24/02/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    09/10/2025   Moin Bloch       Created
	2    14/10/2025   Moin Bloch       Update For New Version

--   EXEC [dbo].[USP_CreateUpdateReleaseForm]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateUpdateReleaseForm]
@ReleaseFromId BIGINT = NULL,
@WorkorderId BIGINT = NULL,
@workOrderPartNoId BIGINT = NULL,
@Country VARCHAR(256) = NULL,
@trackingNo VARCHAR(20) = NULL,
@OrganizationName VARCHAR(MAX) = NULL,
@OrganizationAddress VARCHAR(500) = NULL,
@InvoiceNo VARCHAR(256) = NULL,
@ItemName VARCHAR(256) = NULL,
@Description VARCHAR(500) = NULL,
@PartNumber VARCHAR(256) = NULL,
@Reference VARCHAR(256) = NULL,
@Quantity INT = NULL,
@Batchnumber VARCHAR(256) = NULL,
@status VARCHAR(20) = NULL,
@Remarks VARCHAR(MAX) = NULL,
@Certifies VARCHAR(256) = NULL,
@approved BIT = NULL,
@Nonapproved BIT = NULL,
@AuthorisedSign VARCHAR(256) = NULL,
@AuthorizationNo VARCHAR(256) = NULL,
@PrintedName VARCHAR(256) = NULL,
@Date DATETIME = NULL,
@AuthorisedSign2 VARCHAR(256) = NULL,
@ApprovalCertificate VARCHAR(256) = NULL,
@PrintedName2 VARCHAR(256) = NULL,
@Date2 DATETIME = NULL,
@CFR BIT = NULL,
@Otherregulation BIT = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@CreatedDate DATETIME2(7) = NULL,
@UpdatedDate DATETIME2(7) = NULL,
@IsActive BIT = NULL,
@IsDeleted BIT = NULL,
@is8130from BIT = NULL,
@IsClosed BIT = NULL,
@PDFPath VARCHAR(MAX) = NULL,
@IsEASALicense BIT = NULL,
@EmployeeId BIGINT = NULL,
@FormTypeId INT = NULL,
@IsLocked BIT = NULL,
@Is813013aeOr14ae INT = NULL,
@VersionNo VARCHAR(50) = NULL,
@IsVersionIncrease BIT = NULL,
@isFromSettlement BIT = NULL,
@StockLineId BIGINT = NULL,
@AttachmentId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @firstTimeReleaseFromId	BIGINT = 0

		DECLARE @VerCodePrefix NVARCHAR(50),@VerCode INT

		SELECT @VerCode  = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';
		
		SELECT TOP 1 @VerCodePrefix = [CodePrefix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @VerCode AND [MasterCompanyId] = @MasterCompanyId;

		SET @firstTimeReleaseFromId = @ReleaseFromId

		SET @CreatedDate = GETUTCDATE()
		SET @UpdatedDate = GETUTCDATE()

		IF(@ReleaseFromId > 0)
		BEGIN
			SELECT @VersionNo = [VersionNo], @FormTypeId = [FormTypeId], @Country = [Country] FROM [dbo].[Work_ReleaseFrom_8130] WITH(NOLOCK) WHERE [ReleaseFromId] = @ReleaseFromId;
						
			IF(ISNULL(@IsVersionIncrease,0) = 1)
			BEGIN
			
				UPDATE [dbo].[Work_ReleaseFrom_8130] SET [IsVersionIncrease] = 1 WHERE [ReleaseFromId] = @ReleaseFromId;  

				DECLARE @VersionNum INT= 0;
				IF (@VersionNo IS NOT NULL AND LEN(@VersionNo) > 0)
				BEGIN
					IF (LEN(@VersionNo) > 6)
					BEGIN
						DECLARE @Part2 NVARCHAR(20) = PARSENAME(REPLACE(@VersionNo, '-', '.'), 1);
						IF (@Part2 IS NOT NULL AND ISNUMERIC(@Part2) = 1)
						BEGIN
							SET @VersionNum = CAST(@Part2 AS INT) + 1;
						END
					END
					ELSE
					BEGIN
						SET @VersionNum = CAST(SUBSTRING(@VersionNo, 3, LEN(@VersionNo)) AS INT) + 1;
					END
					SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@VersionNum, ISNULL(@VerCodePrefix,''),''));
				END

				IF(@isFromSettlement IS NOT NULL AND @isFromSettlement = 1)
				BEGIN
					SET @IsLocked = 1;

					INSERT INTO [dbo].[Work_ReleaseFrom_8130] ([WorkorderId],[workOrderPartNoId],[Country],[OrganizationName],[InvoiceNo],[ItemName],[Description],[PartNumber],[Reference],
								[Quantity],[Batchnumber],[status],[Remarks],[Certifies],[approved],[Nonapproved],[AuthorisedSign],[AuthorizationNo],[PrintedName],[Date],[AuthorisedSign2],
								[ApprovalCertificate],[PrintedName2],[Date2],[CFR],[Otherregulation],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
								[IsDeleted],[trackingNo],[OrganizationAddress],[is8130from],[IsClosed],[PDFPath],[IsEASALicense],[EmployeeId],[FormTypeId],[IsLocked],[Is813013aeOr14ae],
								[VersionNo],[IsVersionIncrease])											
						 VALUES (@WorkorderId,@workOrderPartNoId,@Country,@OrganizationName,@InvoiceNo,@ItemName,@Description,@PartNumber,@Reference,
								 @Quantity,@Batchnumber,@status,@Remarks, @Certifies,@approved, @Nonapproved,@AuthorisedSign, @AuthorizationNo, @PrintedName, @Date, @AuthorisedSign2,
								 @ApprovalCertificate, @PrintedName2, @Date2, @CFR, @Otherregulation, @MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, @UpdatedDate,1,
								 0,@trackingNo,@OrganizationAddress, @is8130from, @IsClosed, @PDFPath, @IsEASALicense, @EmployeeId, @FormTypeId, @IsLocked, @Is813013aeOr14ae, 
								 @VersionNo, 0)

						SET @ReleaseFromId = SCOPE_IDENTITY();	
				END
				ELSE
				BEGIN
					SET @IsLocked = 0;

					INSERT INTO [dbo].[Work_ReleaseFrom_8130] ([WorkorderId],[workOrderPartNoId],[Country],[OrganizationName],[InvoiceNo],[ItemName],[Description],[PartNumber],[Reference],
								[Quantity],[Batchnumber],[status],[Remarks],[Certifies],[approved],[Nonapproved],[AuthorisedSign],[AuthorizationNo],[PrintedName],[Date],[AuthorisedSign2],
								[ApprovalCertificate],[PrintedName2],[Date2],[CFR],[Otherregulation],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
								[IsDeleted],[trackingNo],[OrganizationAddress],[is8130from],[IsClosed],[PDFPath],[IsEASALicense],[EmployeeId],[FormTypeId],[IsLocked],[Is813013aeOr14ae],
								[VersionNo],[IsVersionIncrease])											
						 VALUES (@WorkorderId,@workOrderPartNoId,@Country,@OrganizationName,@InvoiceNo,@ItemName,@Description,@PartNumber,@Reference,
								 @Quantity,@Batchnumber,@status,@Remarks, @Certifies,@approved, @Nonapproved,@AuthorisedSign, @AuthorizationNo, @PrintedName, @Date, @AuthorisedSign2,
								 @ApprovalCertificate, @PrintedName2, @Date2, @CFR, @Otherregulation, @MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, @UpdatedDate,1,
								 0,@trackingNo,@OrganizationAddress, @is8130from, @IsClosed, @PDFPath, @IsEASALicense, @EmployeeId, @FormTypeId, @IsLocked, @Is813013aeOr14ae, 
								 @VersionNo, 0) 
							 
					SET @ReleaseFromId = SCOPE_IDENTITY();	
				END
			END
			ELSE
			BEGIN
				UPDATE [dbo].[Work_ReleaseFrom_8130]
				   SET [Country] = @Country
					  ,[OrganizationName] = @OrganizationName
					  ,[InvoiceNo] = @InvoiceNo
					  ,[ItemName] = @ItemName
					  ,[Description] = @Description
					  ,[PartNumber] = @PartNumber
					  ,[Reference] = @Reference
					  ,[Quantity] = @Quantity
					  ,[Batchnumber] = @Batchnumber
					  ,[status] = @status
					  ,[Remarks] = @Remarks
					  ,[Certifies] = @Certifies
					  ,[approved] = @approved
					  ,[Nonapproved] = @Nonapproved
					  ,[AuthorisedSign] = @AuthorisedSign
					  ,[AuthorizationNo] = @AuthorizationNo
					  ,[PrintedName] = @PrintedName
					  ,[Date] = @Date
					  ,[AuthorisedSign2] = @AuthorisedSign2
					  ,[ApprovalCertificate] = @ApprovalCertificate
					  ,[PrintedName2] = @PrintedName2
					  ,[Date2] = @Date2
					  ,[CFR] = @CFR
					  ,[Otherregulation] = @Otherregulation
					  ,[UpdatedBy] = @UpdatedBy
					  ,[UpdatedDate] = @UpdatedDate
					  ,[trackingNo] = @trackingNo
					  ,[OrganizationAddress] = @OrganizationAddress
					  ,[is8130from] = @is8130from
					  ,[IsClosed] = @IsClosed
					  ,[PDFPath] = @PDFPath
					  ,[IsEASALicense] = @IsEASALicense
					  ,[EmployeeId] = @EmployeeId
					  ,[Is813013aeOr14ae] = @Is813013aeOr14ae
				 WHERE [ReleaseFromId] = @ReleaseFromId
			END
			EXEC [dbo].[sp_Update8130fromdata] @WorkorderId,@workOrderPartNoId
		END
		ELSE
		BEGIN
			DECLARE @ReleaseFormTypeId INT,@CodePrefixId BIGINT = 0,@CurrentNummber BIGINT = 0 
			DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50)
			
			SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](1, ISNULL(@VerCodePrefix,''),''));			
			
			SET @IsVersionIncrease = 0;

			SELECT @ReleaseFormTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Easa from Tracking Number';	

			SELECT TOP 1 @CodePrefixId = [CodePrefixId], @CurrentNummber = ISNULL([CurrentNummber],0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodeTypeId] = @ReleaseFormTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0

			IF(@CodePrefixId > 0)
			BEGIN
				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CurrentNummber + 1 WHERE [CodePrefixId] = @CodePrefixId;
			END

			IF(@isFromSettlement IS NOT NULL AND @isFromSettlement = 1)
			BEGIN
				SET @IsLocked = 1;

				INSERT INTO [dbo].[Work_ReleaseFrom_8130] ([WorkorderId],[workOrderPartNoId],[Country],[OrganizationName],[InvoiceNo],[ItemName],[Description],[PartNumber],[Reference],
				            [Quantity],[Batchnumber],[status],[Remarks],[Certifies],[approved],[Nonapproved],[AuthorisedSign],[AuthorizationNo],[PrintedName],[Date],[AuthorisedSign2],
						    [ApprovalCertificate],[PrintedName2],[Date2],[CFR],[Otherregulation],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
						    [IsDeleted],[trackingNo],[OrganizationAddress],[is8130from],[IsClosed],[PDFPath],[IsEASALicense],[EmployeeId],[FormTypeId],[IsLocked],[Is813013aeOr14ae],
						    [VersionNo],[IsVersionIncrease])											
				     VALUES (@WorkorderId,@workOrderPartNoId,@Country,@OrganizationName,@InvoiceNo,@ItemName,@Description,@PartNumber,@Reference,
							 @Quantity,@Batchnumber,@status,@Remarks, @Certifies,@approved, @Nonapproved,@AuthorisedSign, @AuthorizationNo, @PrintedName, @Date, @AuthorisedSign2,
							 @ApprovalCertificate, @PrintedName2, @Date2, @CFR, @Otherregulation, @MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, @UpdatedDate,1,
							 0,@trackingNo,@OrganizationAddress, @is8130from, @IsClosed, @PDFPath, @IsEASALicense, @EmployeeId, @FormTypeId, @IsLocked, @Is813013aeOr14ae, 
							 @VersionNo, 0)

					SET @ReleaseFromId = SCOPE_IDENTITY();	
			END
			ELSE
			BEGIN
				SET @IsLocked = 0;

				INSERT INTO [dbo].[Work_ReleaseFrom_8130] ([WorkorderId],[workOrderPartNoId],[Country],[OrganizationName],[InvoiceNo],[ItemName],[Description],[PartNumber],[Reference],
				            [Quantity],[Batchnumber],[status],[Remarks],[Certifies],[approved],[Nonapproved],[AuthorisedSign],[AuthorizationNo],[PrintedName],[Date],[AuthorisedSign2],
						    [ApprovalCertificate],[PrintedName2],[Date2],[CFR],[Otherregulation],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
						    [IsDeleted],[trackingNo],[OrganizationAddress],[is8130from],[IsClosed],[PDFPath],[IsEASALicense],[EmployeeId],[FormTypeId],[IsLocked],[Is813013aeOr14ae],
						    [VersionNo],[IsVersionIncrease])											
				     VALUES (@WorkorderId,@workOrderPartNoId,@Country,@OrganizationName,@InvoiceNo,@ItemName,@Description,@PartNumber,@Reference,
							 @Quantity,@Batchnumber,@status,@Remarks, @Certifies,@approved, @Nonapproved,@AuthorisedSign, @AuthorizationNo, @PrintedName, @Date, @AuthorisedSign2,
							 @ApprovalCertificate, @PrintedName2, @Date2, @CFR, @Otherregulation, @MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, @UpdatedDate,1,
							 0,@trackingNo,@OrganizationAddress, @is8130from, @IsClosed, @PDFPath, @IsEASALicense, @EmployeeId, @FormTypeId, @IsLocked, @Is813013aeOr14ae, 
							 @VersionNo, 0) 
							 
				SET @ReleaseFromId = SCOPE_IDENTITY();	
			END
			IF(@isFromSettlement IS NOT NULL AND @isFromSettlement = 1)
			BEGIN
			    DECLARE @WorkOrderSettlementId INT=0

				SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Release Certs (e.g. 8130) Reviewed';
				
				UPDATE [dbo].[WorkOrderPartNumber] SET [isLocked] = 1 WHERE [ID] = @workOrderPartNoId;

				UPDATE [dbo].[WorkOrderSettlementDetails] SET [IsMastervalue] = 1 WHERE [workOrderPartNoId] = @workOrderPartNoId AND [WorkOrderSettlementId] = @WorkOrderSettlementId AND ISNULL([Isvalue_NA],0) = 0;

			END

			EXEC [dbo].[sp_Update8130fromdata] @WorkorderId,@workOrderPartNoId
		END

		 -- Add Entry in History Table
		DECLARE @ReleasefromName VARCHAR(30) = 'Releasefrom';
        DECLARE @ReleasefromNameChange VARCHAR(30) = 'ReleasefromChange';
        DECLARE @oldValue VARCHAR(10) = 'False';
        DECLARE @newValue VARCHAR(10) = 'True';
        DECLARE @TemplateBody NVARCHAR(MAX)= '';
		DECLARE @MPNPartNumber VARCHAR(50) = '';
		DECLARE @WorkOrderModuleID INT,@WorkOrderMPNModuleID INT

			-- Modules
		SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';
		SELECT @WorkOrderMPNModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';		

		SELECT @MPNPartNumber = im.[PartNumber] FROM [dbo].[ItemMaster] im WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber] wopn WITH(NOLOCK) ON im.[ItemMasterId] = wopn.[ItemMasterId] WHERE wopn.[ID] = @workOrderPartNoId;
		
		IF(@firstTimeReleaseFromId > 0)
		BEGIN
    		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @ReleasefromNameChange;			   	     
		    SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@MPNPartNumber,''))
		END
		ELSE
		BEGIN
			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @ReleasefromName;			   	     
		    SET @TemplateBody = REPLACE(@TemplateBody, '##WoMPN##', ISNULL(@MPNPartNumber,''))
		END
		                                                                                                                   
		EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,@WorkOrderMPNModuleID,@workOrderPartNoId,@oldValue,@newValue,@TemplateBody,'Releasefrom',@MasterCompanyId,@CreatedBy,@CreatedDate,@CreatedBy,@CreatedDate
			   
	    SELECT @ReleaseFromId [ReleaseFromId]
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateUpdateReleaseForm' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END