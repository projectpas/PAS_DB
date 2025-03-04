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
					MERGE dbo.SalesOrderQuoteCharges AS TARGET
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
	END CATCH
END

SELECT * from SalesOrderQuoteCharges order by 1 desc
SELECT * from CreditMemoCharges