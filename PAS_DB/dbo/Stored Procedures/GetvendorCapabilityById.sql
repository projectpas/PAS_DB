CREATE PROCEDURE GetvendorCapabilityById
@VendorCapsID bigint=0

AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY		
			DECLARE @VendorId Bigint;

			SELECT @VendorId =VendorId FROM VendorCapability WHERE VendorCapabilityId=@VendorCapsID

			SELECT	DISTINCT
					vc.VendorId, 
					vc.VendorCapabilityId,
					vc.CapabilityTypeId,
					v.VendorName,
					v.VendorCode,
					im.PartNumber,
					im.ItemMasterId,
					im.PartDescription,
					m.name AS ManufacturerName,
					m.ManufacturerId,
					vc.VendorRanking,
					ct.CapabilityTypeDesc AS CapabilityTypeName,
					vc.TAT,
					vc.Cost,
					vc.CostDate,
					vc.Memo,
					vc.IsActive,
					vc.IsDeleted,
					vc.CreatedDate,
					vc.CreatedBy,
					vc.UpdatedDate,
					vc.UpdatedBy,
					vc.CurrencyId,
					vc.Currency,
					vc.EmployeeId,
					ct.Description as CapabilityType,
					ct.CapabilityTypeDesc as CapDescription
			FROM dbo.VendorCapability vc  WITH (NOLOCK)
					INNER JOIN dbo.Vendor v  WITH (NOLOCK) ON v.VendorId = vc.VendorId
					LEFT JOIN dbo.ItemMaster im  WITH (NOLOCK) ON vc.ItemMasterId = im.ItemMasterId
					LEFT JOIN dbo.Manufacturer m  WITH (NOLOCK) ON im.ManufacturerId = m.ManufacturerId
					LEFT JOIN dbo.capabilityType ct  WITH (NOLOCK) ON vc.CapabilityTypeId = ct.CapabilityTypeId
			WHERE vc.VendorId=@VendorId and vc.IsDeleted=0 and vc.IsActive=1
			
		END TRY    
		BEGIN CATCH      
			
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetvendorCapabilityById'
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorCapsID, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
		END CATCH
END