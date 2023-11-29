/*************************************************************           
 ** File:   [USP_Lot_AddUpdate]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Create or update Lot General Info
 ** Date:   15/02/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    15/02/2023   Moin Bloch     Created
**************************************************************
 EXEC USP_Lot_AddUpdate 
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_Lot_AddUpdate] 
@LotId bigint OUTPUT,
@LotName varchar(50),
@VendorId bigint NULL=0, 
@ReferenceNumber varchar(50)NULL='',
@OpenDate datetime2(7),
@OriginalCost decimal(18,2)NULL=0,
@LotStatusId int NULL =0,
@ObtainFromTypeId int NULL=0,
@ObtainFromId bigint NULL=0, 
@ObtainFromName varchar(50) NULL='', 
@TraceableToTypeId int NULL=0,
@TraceableToId bigint NULL=0,
@TraceableToName varchar(50) NULL='', 
@ConsignmentId bigint NULL=0,
@EmployeeId bigint,
@ManagementStructureId bigint,
@LegalEntityId bigint NULL=0,
@MasterCompanyId int,
@CreatedBy varchar(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @AppModuleId INT = 0;
		DECLARE @AppModuleCustomerId INT = 0;
		DECLARE @AppModuleVendorId INT = 0;
		DECLARE @AppModuleCompanyId INT = 0;
		DECLARE @AppModuleOthersId INT = 0;

		DECLARE @LotNumber varchar(50) = '';
		SELECT @AppModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Lot';
		SELECT @AppModuleCustomerId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer';
		SELECT @AppModuleVendorId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor';
		SELECT @AppModuleCompanyId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Company';
		SELECT @AppModuleOthersId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Others';
			   		
		IF (@LotId = 0)
		BEGIN
		  DECLARE @Nummber bigint = 0;
		  DECLARE @CodePrefixId bigint = 0;	
		  DECLARE @codePrefix varchar(50)='',@codeSufix varchar(50)='' 

		  SELECT @Nummber = [CurrentNummber], @CodePrefixId = [CodePrefixId],@codePrefix = CP.CodePrefix
			     FROM [DBO].[CodeTypes] CT WITH (NOLOCK)
			          INNER JOIN [DBO].[CodePrefixes] CP WITH (NOLOCK) ON CT.CodeTypeId = CP.CodeTypeId
			          WHERE CT.IsActive = 1 AND CT.IsDeleted = 0 AND CP.IsActive = 1 
					    AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsDeleted = 0 AND CodeType = 'Lot'

		  SET @LotNumber = (SELECT * FROM [DBO].[udfGenerateCodeNumber](CAST(@Nummber AS BIGINT) + 1, @codePrefix,@codeSufix));
		  print '1'		  
		  INSERT INTO [dbo].[Lot]([LotNumber],[LotName],[VendorId],[ReferenceNumber],[OpenDate],[OriginalCost],[LotStatusId],[ObtainFromTypeId]
							     ,[ObtainFromId],[TraceableToTypeId],[TraceableToId],[ConsignmentId],[EmployeeId],[ManagementStructureId]
								 ,[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          VALUES (@LotNumber,@LotName,@VendorId,@ReferenceNumber,@OpenDate,@OriginalCost,@LotStatusId,@ObtainFromTypeId,
                                  @ObtainFromId,@TraceableToTypeId,@TraceableToId,@ConsignmentId,@EmployeeId,@ManagementStructureId,
								  @LegalEntityId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0);	
		  SET @LotId = @@IDENTITY;
		  
		  INSERT INTO [dbo].[LotDetail] ([LotId],[VendorCode],[VendorName],[LotStatusName],[ObtainFromName],
		              [TraceableToName],[ConsignmentNumber],[ConsigneeName],[EmployeeName])
                SELECT @LotId,V.[VendorCode],V.[VendorName],S.[StatusName],
				       CASE WHEN LO.[ObtainFromTypeId] = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN LO.[ObtainFromTypeId] = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN LO.[ObtainFromTypeId] = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN LO.[ObtainFromTypeId] = @AppModuleOthersId THEN @ObtainFromName
					   END,
					   CASE WHEN LO.[TraceableToTypeId] = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN LO.[TraceableToTypeId] = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN LO.[TraceableToTypeId] = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN LO.[TraceableToTypeId] = @AppModuleOthersId THEN @TraceableToName
					   END,
					   LC.ConsignmentNumber,LC.ConsigneeName,(R.[FirstName] + ' ' + R.[LastName])
				FROM [dbo].[Lot] LO WITH(NOLOCK)
					 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON LO.[VendorId] = V.[VendorId] 
					 LEFT JOIN [dbo].[Employee] R WITH(NOLOCK) ON LO.[EmployeeId] = R.[EmployeeId]
					 LEFT JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LO.[LotStatusId] = S.[LotStatusId]
					 LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = LO.[ObtainFromId]
					 LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = LO.[ObtainFromId]
					 LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = LO.[ObtainFromId]
					 LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = LO.[TraceableToId]
					 LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = LO.[TraceableToId]
					 LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = LO.[TraceableToId]
					 LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LO.ConsignmentId = LC.ConsignmentId
                WHERE LO.[LotId] = @LotId; 

		   UPDATE [DBO].[CodePrefixes] SET [CurrentNummber] = (@Nummber + 1) WHERE [CodePrefixId] = @CodePrefixId AND [MasterCompanyId] = @MasterCompanyId;
		   
		   EXEC [dbo].[USP_Lot_AddUpdateMSDetails] @LotId,@ManagementStructureId,@AppModuleId,@MasterCompanyId,@CreatedBy,@CreatedBy,1,0;

		   INSERT INTO [dbo].[LotSetupMaster]
           ([LotId],[IsUseMargin],[IsOverallLotCost],[IsCostToPN],[IsReturnCoreToLot],[IsMaintainStkLine] ,[MasterCompanyId] ,[CreatedBy]
           ,[UpdatedBy] ,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],MarginPercentageId)
			VALUES
           (@LotId,1,0,0,0,0,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0)
		END
		ELSE
		BEGIN			
			UPDATE [dbo].[Lot]
			   SET [LotName] = @LotName
			      ,[VendorId] = @VendorId
			      ,[ReferenceNumber] = @ReferenceNumber
			      ,[OpenDate] = @OpenDate
			      ,[OriginalCost] = @OriginalCost
			      ,[LotStatusId] = @LotStatusId
			      ,[ObtainFromTypeId] = @ObtainFromTypeId
			      ,[ObtainFromId] = @ObtainFromId
			      ,[TraceableToTypeId] = @TraceableToTypeId
			      ,[TraceableToId] = @TraceableToId
			      ,[ConsignmentId] = @ConsignmentId
			      ,[EmployeeId] = @EmployeeId
			      ,[ManagementStructureId] = @ManagementStructureId
			      ,[LegalEntityId] = @LegalEntityId			   
			      ,[UpdatedBy] = @CreatedBy			     
			      ,[UpdatedDate] = GETUTCDATE()			      
			 WHERE [LotId] = @LotId; 
			 
            UPDATE LOD
               SET [VendorCode] =  V.[VendorCode]
                  ,[VendorName] = V.[VendorName]
                  ,[LotStatusName] = S.[StatusName]
                  ,[ObtainFromName] = CASE WHEN LO.[ObtainFromTypeId] = @AppModuleCustomerId THEN CU.[Name] 
						                   WHEN LO.[ObtainFromTypeId] = @AppModuleVendorId THEN VE.[VendorName]
						                   WHEN LO.[ObtainFromTypeId] = @AppModuleCompanyId THEN CO.[Name]	
						                   WHEN LO.[ObtainFromTypeId] = @AppModuleOthersId THEN @ObtainFromName
					                  END
                  ,[TraceableToName] = CASE WHEN LO.[TraceableToTypeId] = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN LO.[TraceableToTypeId] = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN LO.[TraceableToTypeId] = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN LO.[TraceableToTypeId] = @AppModuleOthersId THEN @TraceableToName
					   END
                  ,[ConsignmentNumber] = LC.ConsignmentNumber
                  ,[ConsigneeName] = LC.ConsigneeName
                  ,[EmployeeName] = (R.[FirstName] + ' ' + R.[LastName])
              FROM [dbo].[LotDetail] LOD 
			 INNER JOIN [dbo].[Lot] LO WITH(NOLOCK) ON LOD.[LotId] = LO.[LotId] 		  
			 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON LO.[VendorId] = V.[VendorId] 
			 LEFT JOIN [dbo].[Employee] R WITH(NOLOCK) ON LO.[EmployeeId] = R.[EmployeeId]
			 LEFT JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LO.[LotStatusId] = S.[LotStatusId]
			  LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = LO.[ObtainFromId]
		      LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = LO.[ObtainFromId]
		      LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = LO.[ObtainFromId]
		      LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CU.[CustomerId] = LO.[TraceableToId]
		      LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VE.[VendorId] = LO.[TraceableToId]
		      LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CO.[LegalEntityId] = LO.[TraceableToId]
			  LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LO.ConsignmentId = LC.ConsignmentId
			   WHERE LOD.[LotId] = @LotId; 

			EXEC [dbo].[USP_Lot_AddUpdateMSDetails] @LotId,@ManagementStructureId,@AppModuleId,@MasterCompanyId,@CreatedBy,@CreatedBy,2,0;
					
		END

		Select @LotId AS LotId 
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
          SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_AddUpdate]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100))
            + '@OpenDate = ''' + CAST(ISNULL(@OpenDate, '') AS varchar(100))
            + '@VendorId = ''' + CAST(ISNULL(@VendorId, '') AS varchar(100))             
            + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
            + '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))
            + '@ManagementStructureId = ''' + CAST(ISNULL(@ManagementStructureId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END