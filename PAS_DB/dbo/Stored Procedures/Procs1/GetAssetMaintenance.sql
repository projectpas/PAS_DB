/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <07/30/2021>  
** Description: <GetAssetMaintenance>  
  
Exec [ReverseWorkOrder] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date           Author          Change Description  
** --   --------       -------         --------------------------------
** 1    07/04/2022     Hemant Saliya    GetAssetMaintenance
   2	26 March 2024  Bhargav Saliya   Resolved Default Vendor Binding Issue

EXEC GetAssetMaintenance 128

**************************************************************/ 

CREATE PROCEDURE [dbo].[GetAssetMaintenance]
@AssetRecordId BIGINT
AS
	BEGIN
	BEGIN TRY
		SELECT DISTINCT TOP 1
			[asset].AssetRecordId,
			--gl.AccountCode as GLAccount, 
			magl.AccountCode as GLAccount, 
			CASE WHEN ascal.[AssetRecordId] > 0 THEN 1 ELSE 0 END as AssetCal, 
			CASE WHEN asmai.[AssetRecordId] > 0 THEN 1 ELSE 0 END as AssetMain,
			ISNULL(asmai.AssetIsMaintenanceReqd,0) AssetIsMaintenanceReqd,
			ISNULL(ascal.CalibrationRequired,0) CalibrationRequired,           
			ISNULL(ascal.CertificationRequired,0) CertificationRequired,     
			ISNULL(ascal.InspectionRequired,0) InspectionRequired, 
			ISNULL(asmai.IsWarrantyRequired,0) IsWarrantyRequired,  
			ISNULL(ascal.VerificationRequired,0) VerificationRequired, 
			ISNULL(ascal.AssetCalibrationExpected,'') AssetCalibrationExpected,
			ISNULL(ascal.AssetCalibrationExpectedTolerance,'') AssetCalibrationExpectedTolerance,
			ISNULL(ascal.AssetCalibrationMaxTolerance,'') AssetCalibrationMaxTolerance,
			ISNULL(ascal.AssetCalibrationMemo,'') AssetCalibrationMemo,
			ISNULL(ascal.AssetCalibrationMinTolerance,'') AssetCalibrationMinTolerance,
			ISNULL(ascal.AssetCalibrationMin,'') AssetCalibrationMin,
			ISNULL(ascal.AssetCalibratonMax,'') AssetCalibratonMax,
			ISNULL(ascal.CalibrationCurrencyId,0) CalibrationCurrencyId,  
			ISNULL(ascal.CalibrationDefaultCost,0) CalibrationDefaultCost, 
			ISNULL(ascal.CalibrationDefaultVendorId,0) CalibrationDefaultVendorId,
			ISNULL(ascal.CalibrationFrequencyDays,0) CalibrationFrequencyDays,
			ISNULL(ascal.CalibrationFrequencyMonths,0) CalibrationFrequencyMonths,
			ISNULL(ascal.CalibrationGlAccountId,0) CalibrationGlAccountId,
			ISNULL(ascal.CalibrationMemo,'') CalibrationMemo,
			ISNULL(ascal.CertificationCurrencyId,0) CertificationCurrencyId,
			ISNULL(ascal.CertificationFrequencyMonths,0) CertificationFrequencyMonths,
			ISNULL(ascal.CertificationFrequencyDays,0) CertificationFrequencyDays,
			ISNULL(ascal.CertificationDefaultVendorId,0) CertificationDefaultVendorId,
			ISNULL(ascal.CertificationDefaultCost,0) CertificationDefaultCost,
			ISNULL(ascal.CertificationGlAccountId,0) CertificationGlAccountId,
			ISNULL(ascal.CertificationMemo,'') CertificationMemo,
			ISNULL(ascal.InspectionCurrencyId,0) InspectionCurrencyId,
			ISNULL(ascal.InspectionDefaultCost,0) InspectionDefaultCost,
			ISNULL(ascal.InspectionDefaultVendorId,0) InspectionDefaultVendorId,
			ISNULL(ascal.InspectionFrequencyDays,0) InspectionFrequencyDays,
			ISNULL(ascal.InspectionFrequencyMonths,0) InspectionFrequencyMonths,
			ISNULL(ascal.InspectionGlaAccountId,0) InspectionGlaAccountId,
			ISNULL(ascal.InspectionMemo,'') InspectionMemo,
			ISNULL(ascal.VerificationCurrencyId,0) VerificationCurrencyId,
			ISNULL(ascal.VerificationDefaultCost,0) VerificationDefaultCost,
			ISNULL(ascal.VerificationDefaultVendorId,0) VerificationDefaultVendorId,
			ISNULL(ascal.VerificationFrequencyDays,0) VerificationFrequencyDays,
			ISNULL(ascal.VerificationFrequencyMonths,0) VerificationFrequencyMonths,
			ISNULL(ascal.VerificationGlAccountId,0) VerificationGlAccountId,
			ISNULL(ascal.VerificationMemo,'') VerificationMemo,
			ISNULL((SELECT Code FROM dbo.Currency WHERE CurrencyId = ascal.CalibrationCurrencyId),'') as CalibrationCurrencyName,
			ISNULL((SELECT Code FROM dbo.Currency WHERE CurrencyId = ascal.CertificationCurrencyId),'') as CertificationCurrencyName,
			ISNULL((SELECT Code FROM dbo.Currency WHERE CurrencyId = ascal.InspectionCurrencyId),'') as InspectionCurrencyName,
			ISNULL((SELECT Code FROM dbo.Currency WHERE CurrencyId = ascal.VerificationCurrencyId),'') as VerificationCurrencyName,
			ISNULL(cagl.AccountCode + '-' + cagl.AccountName,'') as CalibrationGlAccount,
			ISNULL(cav.VendorName, '') as CalibrationVendor,
			ISNULL(cegl.AccountCode + '-' + cegl.AccountName,'') as CertificationGlAccount,
			ISNULL(cev.VendorName, '') as CertificationVendor,
			ISNULL(ingl.AccountCode + '-' + ingl.AccountName,'') as InspectionGlAccount,
			ISNULL(inv.VendorName, '') as InspectionVendor,
			ISNULL(vegl.AccountCode + '-' + vegl.AccountName,'') as VerificationGlAccount,
			ISNULL(vev.VendorName, '') as VerificationVendor,
			ISNULL(asmai.MaintenanceDefaultVendorId,0) MaintenanceDefaultVendorId,
			ISNULL(asmai.WarrantyDefaultVendorId,0) WarrantyDefaultVendorId,
			ISNULL(asmai.MaintenanceGLAccountId,0) MaintenanceGLAccountId,
			ISNULL(asmai.MaintenanceFrequencyDays,0) MaintenanceFrequencyDays,
			ISNULL(asmai.MaintenanceFrequencyMonths,0) MaintenanceFrequencyMonths,
			ISNULL(asmai.MaintenanceMemo, '') as MaintenanceMemo,
			ISNULL(asmai.WarrantyGLAccountId,0) WarrantyGLAccountId,
			ISNULL(asmai.MaintenanceMemo, '') as MaintenanceMemo,
			ISNULL(asmai.WarrantyCompany, '') as WarrantyCompany,
			ISNULL(magl.AccountCode + '-' + magl.AccountName,'') as MaintenanceGlAccount,
			ISNULL(mav.VendorName, '') as MaintenanceVendor,
			ISNULL(wagl.AccountCode + '-' + wagl.AccountName,'') as WarrantyGlACoount,
			ISNULL(wav.VendorName, '') as WarrantyVendor,
			CASE WHEN ISNULL(ascal.CalibrationProvider,'') = '' THEN 'Vendor' ELSE ascal.CalibrationProvider END as CalibrationProvider,
			CASE WHEN ISNULL(ascal.CertificationProvider,'') = '' THEN 'Vendor' ELSE ascal.CertificationProvider END as CertificationProvider,
			CASE WHEN ISNULL(ascal.InspectionProvider,'') = '' THEN 'Vendor' ELSE ascal.InspectionProvider END as InspectionProvider,
			CASE WHEN ISNULL(ascal.VerificationProvider,'') = '' THEN 'Vendor' ELSE ascal.VerificationProvider END as VerificationProvider
		FROM dbo.[Asset] AS [asset] WITH(NOLOCK)
			LEFT JOIN dbo.[AssetCalibration]  AS [ascal] WITH(NOLOCK) ON [asset].[AssetRecordId] = [ascal].[AssetRecordId]
			LEFT JOIN dbo.[AssetMaintenance] AS [asmai] WITH(NOLOCK) ON [asset].[AssetRecordId] = [asmai].[AssetRecordId]
			LEFT JOIN dbo.[GLAccount] AS [cagl] WITH(NOLOCK) ON [ascal].[CalibrationGlAccountId] = [cagl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [cav] WITH(NOLOCK) ON [ascal].[CalibrationDefaultVendorId] = [cav].[VendorId]
			LEFT JOIN dbo.[GLAccount] AS [cegl] WITH(NOLOCK)ON [ascal].[CertificationGlAccountId] = [cegl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [cev] WITH(NOLOCK) ON   [ascal].[CertificationDefaultVendorId] = [cev].[VendorId]
			LEFT JOIN dbo.[GLAccount] AS [ingl] WITH(NOLOCK) ON [ascal].[InspectionGlaAccountId] = [ingl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [inv] WITH(NOLOCK) ON [ascal].[InspectionDefaultVendorId] = [inv].[VendorId]
			LEFT JOIN dbo.[GLAccount] AS [vegl] WITH(NOLOCK) ON [ascal].[VerificationGlAccountId] = [vegl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [vev] WITH(NOLOCK) ON [ascal].[VerificationDefaultVendorId] = [vev].[VendorId]
			LEFT JOIN dbo.[GLAccount] AS [magl] WITH(NOLOCK) ON [asmai].[MaintenanceGLAccountId] = [magl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [mav] WITH(NOLOCK) ON [asmai].[MaintenanceDefaultVendorId] = [mav].[VendorId]
			LEFT JOIN dbo.[GLAccount] AS [wagl] WITH(NOLOCK) ON [asmai].[WarrantyGLAccountId] = [wagl].[GLAccountId]
			LEFT JOIN dbo.[Vendor] AS [wav] WITH(NOLOCK) ON [asmai].[WarrantyDefaultVendorId] = [wav].[VendorId]
			--LEFT JOIN dbo.[GLAccount] AS [gl] WITH(NOLOCK) ON [asmai].[MaintenanceGLAccountId] = [gl].[GLAccountId]
			WHERE asset.AssetRecordId = @AssetRecordId
	END TRY
	BEGIN CATCH
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAssetMaintenance' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetRecordId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID				= @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END