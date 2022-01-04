CREATE PROCEDURE usp_SaveVendorCapability
@tbl_VendorCapabilityType VendorCapabilityType READONLY

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
				IF OBJECT_ID(N'tempdb..#VendorCapabilityType') IS NOT NULL
				BEGIN
				DROP TABLE #VendorCapabilityType 
				END

				CREATE TABLE #VendorCapabilityType 
				(
				 ID BIGINT NOT NULL IDENTITY, 
				 [VendorCapabilityId] [bigint] NULL,
				 [VendorId] [bigint]  NULL,				
				 [CapabilityTypeId] [int]  NULL,
				 [CapabilityTypeName] [varchar](100) NULL,
				 [CapabilityTypeDescription] [varchar](100) NULL,
				 [ManufacturerId] [bigint]  NULL,		
				 [ManufacturerName] [varchar](100) NULL,
				 [VendorRanking] [int] NULL,
				 [ItemMasterId] [bigint]  NULL,
				 [PartNumber] [varchar](100) NULL,
				 [PartDescription] [varchar](100) NULL,
				 [TAT] [int] NULL,
				 [Cost] [decimal] NULL,
				 [Memo] [nvarchar](max) NULL,
				 [capabilityDescription] [varchar](100) NULL,
				 [IsPMA] [bit] NULL,
				 [IsDER] [bit] NULL,
				 [CostDate] [datetime] NULL,
				 [CurrencyId] [int] NULL,
				 [Currency] [varchar](50) NULL,
				 [EmployeeId] [int] NULL,
				 [MasterCompanyId] [int] NULL,
				 [CreatedBy] [varchar](50) NULL,
				 [UpdatedBy] [varchar](50) NULL,
				 [CreatedDate] [datetime] null,
				 [UpdatedDate] [datetime] NULL,
				 [IsActive] [BIT] NULL,
				 [IsDeleted] [BIT] NULL,
				 isvalid bit default 1,
				 [message] [varchar](100) NULL
				)

				INSERT INTO #VendorCapabilityType ([VendorCapabilityId],[VendorId],[CapabilityTypeId],[CapabilityTypeName],[CapabilityTypeDescription],
													[ManufacturerId],[ManufacturerName],[VendorRanking],[ItemMasterId],[PartNumber],[PartDescription],
													[TAT],[Cost],[Memo],[IsPMA],[IsDER],[CostDate],[CurrencyId],[Currency],[EmployeeId]
													,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
				                                  SELECT [VendorCapabilityId],[VendorId],[CapabilityTypeId],[CapabilityTypeName],[CapabilityTypeDescription],
													[ManufacturerId],[ManufacturerName],[VendorRanking],[ItemMasterId],[PartNumber],[PartDescription],
													[TAT],[Cost],[Memo],[IsPMA],[IsDER],[CostDate],[CurrencyId],[Currency],[EmployeeId]
													,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
												  FROM @tbl_VendorCapabilityType

				UPDATE #VendorCapabilityType SET IsValid = 0, [Message] = 'Vendor, part ,Cap Type Combination Record Already Exist'
				           FROM #VendorCapabilityType t
						        INNER JOIN dbo.VendorCapability vc WITH (NOLOCK)  
								    ON t.VendorId = vc.VendorId 
										AND t.CapabilityTypeId = vc.CapabilityTypeId 
										AND t.ItemMasterId = vc.ItemMasterId
										AND t.VendorCapabilityId != vc.VendorCapabilityId
										AND t.VendorCapabilityId > 0
			
				UPDATE #VendorCapabilityType SET IsValid = 0, [Message] = 'Record Already Exist'
				           FROM #VendorCapabilityType t
						        INNER JOIN dbo.VendorCapability vc WITH (NOLOCK)  
								    ON t.VendorId = vc.VendorId 
										AND t.CapabilityTypeId = vc.CapabilityTypeId 
										AND t.ItemMasterId = vc.ItemMasterId
										AND t.VendorCapabilityId = 0

				

			INSERT INTO [dbo].[VendorCapability]
           ([VendorId],[CapabilityTypeId],[CapabilityTypeName],[ItemMasterId],[CapabilityTypeDescription]
           ,[VendorRanking],[IsPMA],[IsDER],[Cost],[TAT],[Memo],[MasterCompanyId],[CreatedBy]
           ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartNumber],[PartDescription]
           ,[ManufacturerId],[ManufacturerName],[CostDate],[CurrencyId],[Currency],[EmployeeId])
			SELECT VendorId,CapabilityTypeId,CapabilityTypeName,ItemMasterId,CapabilityTypeDescription,
			VendorRanking,[IsPMA],[IsDER],[Cost],[TAT],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy]
			,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartNumber],[PartDescription]
           ,[ManufacturerId],[ManufacturerName],[CostDate],[CurrencyId],[Currency],[EmployeeId]
			FROM #VendorCapabilityType tmp
			where tmp.isvalid=1 AND tmp.VendorCapabilityId = 0
			---------------------------------Update Caps---------------------
				UPDATE [dbo].[VendorCapability]
			   SET [VendorId] = t.VendorId
				  ,[CapabilityTypeId] = t.CapabilityTypeId
				  ,[CapabilityTypeName] = t.CapabilityTypeName
				  ,[ItemMasterId] = t.ItemMasterId
				  ,[CapabilityTypeDescription] = t.CapabilityTypeDescription
				  ,[VendorRanking] = t.VendorRanking
				  ,[IsPMA] = t.IsPMA
				  ,[IsDER] = t.IsDER
				  ,[Cost] = t.Cost
				  ,[TAT] = t.TAT
				  ,[Memo] = t.Memo
				  ,[MasterCompanyId] = t.MasterCompanyId    
				  ,[UpdatedBy] = t.UpdatedBy     
				  ,[UpdatedDate] = t.UpdatedDate
				  ,[IsActive] = t.IsActive
				  ,[IsDeleted] = t.IsDeleted
				  ,[PartNumber] = t.PartNumber
				  ,[PartDescription] = t.PartDescription
				  ,[ManufacturerId] = t.ManufacturerId
				  ,[ManufacturerName] = t.ManufacturerName
				  ,[CostDate] = t.CostDate
				  ,[CurrencyId] = t.CurrencyId
				  ,[Currency] = t.Currency
				  ,[EmployeeId] = t.EmployeeId
				  FROM #VendorCapabilityType t
			 WHERE t.isvalid=1 AND t.VendorCapabilityId > 0


				SELECT * FROM  #VendorCapabilityType  where isvalid=0				
				
				END
				COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveVendorCapability' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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