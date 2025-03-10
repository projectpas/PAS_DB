/*************************************************************             
 ** File:   [CreateSalesOrderQuoteChargesDetails]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used CreateSalesOrderQuoteChargesDetails
 ** Purpose:           
 ** Date:  04/03/2025        
            
 ** PARAMETERS: @tbl_SalesOrderQuoteChargesType table type [SalesOrderQuoteChargesType]
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    04/03/2025		EKTA CHANDEGRA	 Created  

declare @p1 dbo.SalesOrderQuoteChargesType
insert into @p1 values(204,914,3371,2,NULL,1,0,N'AIRCRAFT ON THE GOUND',123.00,123.00,1,29851,2,123.00,123.00,2,N'',N'EKTA CHANDEGRA',N'EKTA CHANDEGRA','2025-03-04 12:01:53.1910000','2025-03-04 12:01:53.1920000',1,0,0,N'',NULL,NULL,7,7,3)
insert into @p1 values(0,914,3371,31,NULL,1,0,N'Evaluation Fee means a variable fee which shall be determined by the Council from time to time for evaluating qualifications for admission to different classes of membership.',124.00,124.00,1,29851,2,124.00,124.00,2,NULL,N'EKTA CHANDEGRA',N'EKTA CHANDEGRA','2025-03-04 12:03:14.0250000','2025-03-04 12:03:14.0250000',1,0,0,NULL,NULL,NULL,NULL,NULL,3)
insert into @p1 values(0,914,3371,5,NULL,12,0,N'GOLD PLATING',2467.00,29604.00,1,29851,2,29604.00,2467.00,2,NULL,N'EKTA CHANDEGRA',N'EKTA CHANDEGRA','2025-03-04 12:03:25.9690000','2025-03-04 12:03:25.9710000',1,0,0,NULL,NULL,NULL,NULL,NULL,42)

exec dbo.CreateSalesOrderQuoteChargesDetails @tbl_SalesOrderQuoteChargesType=@p1
************************************************************************/ 
CREATE   PROCEDURE [dbo].[CreateSalesOrderQuoteChargesDetails]
(
	@tbl_SalesOrderQuoteChargesType SalesOrderQuoteChargesType READONLY
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF((SELECT COUNT(SalesOrderQuoteId) FROM @tbl_SalesOrderQuoteChargesType) > 0)
				BEGIN
					DECLARE @SalesOrderQuoteId BIGINT
					DECLARE @SalesOrderQuotePartId BIGINT
					DECLARE @CreatedBy VARCHAR(256)
					DECLARE @MasterCompanyId INT

					SET @SalesOrderQuoteId = (SELECT TOP 1 SalesOrderQuoteId FROM @tbl_SalesOrderQuoteChargesType);
					MERGE [dbo].[SalesOrderQuoteCharges] AS TARGET
					USING @tbl_SalesOrderQuoteChargesType AS SOURCE ON (TARGET.SalesOrderQuoteId = SOURCE.SalesOrderQuoteId AND
																		TARGET.SalesOrderQuoteChargesId = SOURCE.SalesOrderQuoteChargesId)
					WHEN MATCHED
					THEN UPDATE
						SET
						TARGET.[SalesOrderQuotePartId] = SOURCE.[SalesOrderQuotePartId]
						,TARGET.[ChargesTypeId] = SOURCE.[ChargesTypeId]
						,TARGET.[VendorId] = SOURCE.[VendorId]
						,TARGET.[Quantity] = SOURCE.[Quantity]
						,TARGET.[MarkupPercentageId] = SOURCE.[MarkupPercentageId]
						,TARGET.[Description] = SOURCE.[Description]
						,TARGET.[UnitCost] = SOURCE.[UnitCost]
						,TARGET.[ExtendedCost] = SOURCE.[ExtendedCost]
						,TARGET.[MasterCompanyId] = SOURCE.[MasterCompanyId]
						,TARGET.[MarkupFixedPrice] = SOURCE.[MarkupFixedPrice]
						,TARGET.[BillingMethodId] = SOURCE.[BillingMethodId]
						,TARGET.[BillingAmount] = SOURCE.[BillingAmount]
						,TARGET.[BillingRate] = SOURCE.[BillingRate]
						,TARGET.[HeaderMarkupId] = SOURCE.[HeaderMarkupId]
						,TARGET.[RefNum] = SOURCE.[RefNum]
						,TARGET.[UpdatedBy] = SOURCE.[UpdatedBy]
						,TARGET.[UpdatedDate] = SOURCE.[UpdatedDate]
						,TARGET.[IsActive] = SOURCE.[IsActive]
						,TARGET.[IsDeleted] = SOURCE.[IsDeleted]
						,TARGET.[HeaderMarkupPercentageId] = SOURCE.[HeaderMarkupPercentageId]
						,TARGET.[VendorName] = SOURCE.[VendorName]
						,TARGET.[ChargeName] = SOURCE.[ChargeName]
						,TARGET.[MarkupName] = SOURCE.[MarkupName]
						,TARGET.[ItemMasterId] = SOURCE.[ItemMasterId]
						,TARGET.[ConditionId] = SOURCE.[ConditionId]
						,TARGET.[UnitOfMeasureId] = SOURCE.[UnitOfMeasureId]

					WHEN NOT MATCHED BY TARGET
					THEN
						INSERT
							([SalesOrderQuoteId] 
							,[SalesOrderQuotePartId]
							,[ChargesTypeId] 
							,[VendorId] 
							,[Quantity] 
							,[MarkupPercentageId] 
							,[Description] 
							,[UnitCost] 
							,[ExtendedCost] 
							,[MasterCompanyId] 
							,[MarkupFixedPrice]
							,[BillingMethodId]
							,[BillingAmount]
							,[BillingRate] 
							,[HeaderMarkupId] 
							,[RefNum] 
							,[CreatedBy]
							,[UpdatedBy] 
							,[CreatedDate] 
							,[UpdatedDate] 
							,[IsActive] 
							,[IsDeleted]
							,[HeaderMarkupPercentageId] 
							,[VendorName] 
							,[ChargeName] 
							,[MarkupName] 
							,[ItemMasterId] 
							,[ConditionId] 
							,[UnitOfMeasureId] )
						VALUES
							(
							 SOURCE.[SalesOrderQuoteId] 
							,SOURCE.[SalesOrderQuotePartId]
							,SOURCE.[ChargesTypeId] 
							,SOURCE.[VendorId] 
							,SOURCE.[Quantity] 
							,SOURCE.[MarkupPercentageId] 
							,SOURCE.[Description] 
							,SOURCE.[UnitCost] 
							,SOURCE.[ExtendedCost] 
							,SOURCE.[MasterCompanyId] 
							,SOURCE.[MarkupFixedPrice]
							,SOURCE.[BillingMethodId]
							,SOURCE.[BillingAmount]
							,SOURCE.[BillingRate] 
							,SOURCE.[HeaderMarkupId] 
							,SOURCE.[RefNum] 
							,SOURCE.[CreatedBy]
							,SOURCE.[UpdatedBy] 
							,SOURCE.[CreatedDate] 
							,SOURCE.[UpdatedDate] 
							,SOURCE.[IsActive] 
							,SOURCE.[IsDeleted]
							,SOURCE.[HeaderMarkupPercentageId] 
							,SOURCE.[VendorName] 
							,SOURCE.[ChargeName] 
							,SOURCE.[MarkupName] 
							,SOURCE.[ItemMasterId] 
							,SOURCE.[ConditionId] 
							,SOURCE.[UnitOfMeasureId]
							);
						END

						SELECT TOP 1 @SalesOrderQuoteId =  SalesOrderQuoteId,
						@SalesOrderQuotePartId = SalesOrderQuotePartId,
						@CreatedBy = CreatedBy,
						@MasterCompanyId = MasterCompanyId
						FROM @tbl_SalesOrderQuoteChargesType

						IF(@SalesOrderQuoteId > 0 AND @SalesOrderQuotePartId > 0)
						BEGIN
							EXEC usp_UpdateSOQPartCostDetails @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;
						END

					    SELECT TOP 1 @SalesOrderQuoteId = SalesOrderQuoteId FROM @tbl_SalesOrderQuoteChargesType WHERE SalesOrderQuoteId IS NOT NULL;
					    EXEC UpdateSOQChargeNameColumnsWithId @SalesOrderQuoteId;

				END
			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'CreateSalesOrderQuoteChargesDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''                  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);
	END CATCH
END