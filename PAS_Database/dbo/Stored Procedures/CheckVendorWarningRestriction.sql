/************************************************************************************           
 ** File:   [CheckVendorWarningRestriction]           
 ** Author: 
 ** Description: This stored procedure is used to Check Vendor Warning/Restriction.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   --------				 -------		  --------------------------------          
	 1    20-03-2025			Amit Ghediya		Created

	 EXEC [dbo].[CheckVendorWarningRestriction] 4760,1,1
****************************************************************************************/
CREATE    PROCEDURE [dbo].[CheckVendorWarningRestriction]
	@VendorId bigint = null,
	@MasterCompanyId INT,
	@IsForPO BIT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
			DECLARE @VendorOrderTypeId INT,
					@VendorAuditTypeId INT,
					@VendorAuditType NVARCHAR(400),
					@IsWarningRestriction INT,
					@Expired VARCHAR(10) = 'Expired',
					@PoOrderTypeName VARCHAR(100) = 'Purchase Order',
					@RoOrderTypeName VARCHAR(100) = 'Repair Order',
					@LoopID AS INT,
					@TotCount AS INT,
					@MultipleVendorAuditType VARCHAR(MAX),
					@IsExpired BIT,
					@WarningMsg VARCHAR(256) = '##AuditType## audit type is Expired </Br> Continue to process this action?',
					@RestrictionMsg VARCHAR(256) = '##AuditType## audit type is Expired';

			--Get Order Type is for PO/RO
			IF(@IsForPO = 1)
			BEGIN 
				-- For PurchaseOrder
				SELECT @VendorOrderTypeId = [VendorOrderTypeId] 
				FROM [DBO].[VendorOrderType] WITH(NOLOCK)
				WHERE OrderTypeName = @PoOrderTypeName;
			END
			ELSE
			BEGIN 
				-- For RepairOrder
				SELECT @VendorOrderTypeId = [VendorOrderTypeId] 
				FROM [DBO].[VendorOrderType] WITH(NOLOCK)
				WHERE OrderTypeName = @RoOrderTypeName;
			END

			--Get Warning or Restriction from Vendor.
			SELECT @IsWarningRestriction = ISNULL([IsWarningRestriction],0)
			FROM [DBO].[Vendor] WITH(NOLOCK) 
			WHERE [VendorId] = @VendorId
			AND [MasterCompanyId] = @MasterCompanyId;


			--Create Temp table for multiple expired VendorAudit Type
			IF OBJECT_ID(N'tempdb..#VendorAuditType') IS NOT NULL
			BEGIN
				DROP TABLE #VendorAuditType
			END

			CREATE TABLE #VendorAuditType
			(
				[ID] bigint NOT NULL IDENTITY,
				[VendorAuditTypeId] BIGINT NULL,
				[VendorAuditType] NVARCHAR(400) NULL
			)

			IF(@IsWarningRestriction = 1 OR @IsWarningRestriction = 2) --If Vendor is Restriction/Warning
			BEGIN
				IF EXISTS(SELECT TOP 1 VendorAuditInfoId FROM [DBO].[VendorAuditInfo] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND VendorId = @VendorId AND VendorOrderTypeId = @VendorOrderTypeId AND Expired = @Expired)
				BEGIN
					INSERT INTO #VendorAuditType 
						   ([VendorAuditTypeId],[VendorAuditType])
					SELECT VAI.[VendorAuditTypeId],VAT.[VendorAuditType] 
						FROM [DBO].[VendorAuditInfo] VAI WITH(NOLOCK)
						INNER JOIN [DBO].[VendorAuditType] VAT WITH(NOLOCK) ON VAI.VendorAuditTypeId = VAT.VendorAuditTypeId
						WHERE VAI.MasterCompanyId = @MasterCompanyId 
						AND VAI.VendorId = @VendorId 
						AND VAI.VendorOrderTypeId = @VendorOrderTypeId 
						AND VAI.Expired = @Expired;

					SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #VendorAuditType;

					WHILE (@LoopID <= @TotCount)
					BEGIN
						SELECT @VendorAuditType = VendorAuditType
						FROM #VendorAuditType WHERE ID = @LoopID;

						IF(@MultipleVendorAuditType != '')
						BEGIN
							SET @MultipleVendorAuditType = @MultipleVendorAuditType + ',' + @VendorAuditType;
						END
						ELSE
						BEGIN
							SET @MultipleVendorAuditType = @VendorAuditType;
						END

						SET @LoopID = @LoopID + 1;
					END

					--Set msg based on Warning
					IF(@IsWarningRestriction = 1)
					BEGIN
						SET @WarningMsg = REPLACE(@WarningMsg, '##AuditType##', ISNULL(@MultipleVendorAuditType,''));
						SET @MultipleVendorAuditType = @WarningMsg;
					END

					--set msg based on Restriction
					IF(@IsWarningRestriction = 2)
					BEGIN
						SET @RestrictionMsg = REPLACE(@RestrictionMsg, '##AuditType##', ISNULL(@MultipleVendorAuditType,''));
						SET @MultipleVendorAuditType = @RestrictionMsg;
					END
					SET @IsExpired = 1;
				END
				ELSE
				BEGIN
					SET @MultipleVendorAuditType = '';
					SET @IsExpired = 0;
				END
			END
			ELSE --If Vendor is None
			BEGIN
				SET @MultipleVendorAuditType = '';
				SET @IsExpired = 0;
			END
			
			SELECT ISNULL(@MultipleVendorAuditType,'') AS VendorAuditType, @IsExpired AS IsExpired,@IsWarningRestriction AS IsWarningRestriction;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckVendorWarningRestriction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END