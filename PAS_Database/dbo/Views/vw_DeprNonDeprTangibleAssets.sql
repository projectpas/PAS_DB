

CREATE VIEW [dbo].[vw_DeprNonDeprTangibleAssets]
AS
SELECT AAT.[DeprNonDeprTangibleAssetsId]
	,AAT.[AssetAttributeTypeId]
      ,AAT.[TangibleClassId]
	  ,ATC.[TangibleClassName] 'TangibleClassName'
	  ,AT2.[AssetAttributeTypeName]
	  ,AAT.[Description] AS [Description]
      ,AAT.[AssetDeprMethodId]
	  ,ADM.[AssetDepreciationMethodName] 'DepreciationMethodName'

	  ,AAT.[ResidualPercentage]
	  ,PER.[PercentValue] 'ResidualPercentageValue'
	  ,AAT.[AssetLife]
	  ,AAT.[DepreciationFrequencyId]
	  ,FI.[Name] 'DepreciationFrequencyName'

	  ,AAT.[CalibratedGLAccountId]
	  ,CGL.[AccountCode] +'-'+ CGL.[AccountName] 'CalibratedGLAccountName'
	  ,AAT.[AccumDeprGLAccountId]
	  ,ADGL.[AccountCode] +'-'+ ADGL.[AccountName] 'AccumDeprGLAccountName'
	  
	  ,AAT.[AcquiredGLAccountId]
	  ,AGL.[AccountCode] +'-'+ AGL.[AccountName] 'AcquiredGLAccountName'
      ,AAT.[DeprExpenseGLAccountId]
	  ,DGL.[AccountCode] +'-'+ DGL.[AccountName] 'DeprExpenseGLAccountName'
      ,AAT.[AssetSaleGLAccountId]
	  ,ASG.[AccountCode] +'-'+ ASG.[AccountName] 'AssetSaleGLAccountName'
      ,AAT.[AssetWriteOffGLAccountId]
	  ,AWG.[AccountCode] +'-'+ AWG.[AccountName] 'AssetWriteOffGLAccountName'
      ,AAT.[AssetWriteDownGLAccountId]
	  ,ARG.[AccountCode] +'-'+ ARG.[AccountName] 'AssetWriteDownGLAccountName'
      ,AAT.[MasterCompanyId]
      ,AAT.[CreatedBy]
      ,AAT.[CreatedDate]
      ,AAT.[UpdatedBy]
      ,AAT.[UpdatedDate]
      ,AAT.[IsActive]
      ,AAT.[IsDeleted]
  FROM [dbo].[DeprNonDeprTangibleAssets] AAT WITH (NOLOCK)
  LEFT JOIN [dbo].[AssetAttributeType] AT2 WITH (NOLOCK) ON AAT.AssetAttributeTypeId = AT2.AssetAttributeTypeId
  LEFT JOIN [dbo].[TangibleClass] ATC WITH (NOLOCK) ON AAT.TangibleClassId = ATC.TangibleClassId
  LEFT JOIN [dbo].[AssetDepreciationMethod] ADM WITH (NOLOCK) ON AAT.AssetDeprMethodId = ADM.AssetDepreciationMethodId
  LEFT JOIN [dbo].[Percent] PER WITH (NOLOCK) ON AAT.ResidualPercentage = PER.PercentId
  LEFT JOIN [dbo].[AssetDepreciationFrequency] FI WITH (NOLOCK) ON AAT.DepreciationFrequencyId = FI.AssetDepreciationFrequencyId
  LEFT JOIN [dbo].[GLAccount] AGL WITH (NOLOCK) ON AAT.AcquiredGLAccountId = AGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] DGL WITH (NOLOCK) ON AAT.DeprExpenseGLAccountId = DGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ASG WITH (NOLOCK) ON AAT.AssetSaleGLAccountId = ASG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] AWG WITH (NOLOCK) ON AAT.AssetWriteOffGLAccountId = AWG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ARG WITH (NOLOCK) ON AAT.AssetWriteDownGLAccountId = ARG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] CGL WITH (NOLOCK) ON AAT.CalibratedGLAccountId = CGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ADGL WITH (NOLOCK) ON AAT.AccumDeprGLAccountId = ADGL.GLAccountId
GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_DeprNonDeprTangibleAssets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'0
         End
         Begin Table = "DGL"
            Begin Extent = 
               Top = 1183
               Left = 48
               Bottom = 1346
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ASG"
            Begin Extent = 
               Top = 1351
               Left = 48
               Bottom = 1514
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "AWG"
            Begin Extent = 
               Top = 1519
               Left = 48
               Bottom = 1682
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ARG"
            Begin Extent = 
               Top = 1687
               Left = 48
               Bottom = 1850
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CGL"
            Begin Extent = 
               Top = 1855
               Left = 48
               Bottom = 2018
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ADGL"
            Begin Extent = 
               Top = 2023
               Left = 48
               Bottom = 2186
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_DeprNonDeprTangibleAssets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -240
         Left = 0
      End
      Begin Tables = 
         Begin Table = "AAT"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 349
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ATC"
            Begin Extent = 
               Top = 175
               Left = 48
               Bottom = 338
               Right = 277
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ATT"
            Begin Extent = 
               Top = 343
               Left = 48
               Bottom = 506
               Right = 314
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ADM"
            Begin Extent = 
               Top = 511
               Left = 48
               Bottom = 674
               Right = 359
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PER"
            Begin Extent = 
               Top = 679
               Left = 48
               Bottom = 842
               Right = 264
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FI"
            Begin Extent = 
               Top = 847
               Left = 48
               Bottom = 1010
               Right = 344
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "AGL"
            Begin Extent = 
               Top = 1015
               Left = 48
               Bottom = 1178
               Right = 324
            End
            DisplayFlags = 280
            TopColumn = ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_DeprNonDeprTangibleAssets';

