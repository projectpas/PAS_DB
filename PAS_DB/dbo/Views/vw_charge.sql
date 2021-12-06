CREATE VIEW [dbo].[vw_charge]
AS
SELECT        dbo.Charge.ChargeId, dbo.Charge.Description,dbo.Charge.Cost,dbo.Charge.Price,dbo.Charge.SequenceNo, dbo.Charge.GLAccountId, dbo.Charge.MasterCompanyId, dbo.Charge.CreatedBy, dbo.Charge.Memo, dbo.Charge.UpdatedBy, dbo.Charge.CreatedDate, dbo.Charge.UpdatedDate, 
                         dbo.Charge.IsActive, dbo.Charge.IsDeleted, dbo.Charge.ChargeType, dbo.GLAccount.AccountCode, dbo.GLAccount.AccountName, dbo.Charge.CurrencyId,dbo.Currency.Code,dbo.Charge.UnitOfMeasureId,dbo.UnitOfMeasure.ShortName
FROM            dbo.Charge INNER JOIN
                         dbo.GLAccount ON dbo.Charge.GLAccountId = dbo.GLAccount.GLAccountId
				LEFT JOIN dbo.Currency ON dbo.Currency.CurrencyId = dbo.Charge.CurrencyId
				LEFT JOIN dbo.UnitOfMeasure ON dbo.UnitOfMeasure.UnitOfMeasureId = dbo.Charge.UnitOfMeasureId